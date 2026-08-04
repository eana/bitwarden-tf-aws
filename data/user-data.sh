#!/bin/bash
# shellcheck disable=SC2154
set -exuo pipefail

function retry {
  local retries=$1
  shift
  local count=0
  until "$@"; do
    exit=$?
    wait=$((2 ** count))
    count=$((count + 1))
    if [ "$count" -lt "$retries" ]; then
      echo "Retry $count/$retries exited $exit, retrying in $wait seconds..."
      sleep $wait
    else
      echo "Retry $count/$retries exited $exit, no more retries left."
      return $exit
    fi
  done
  return 0
}

# HACK: t4g.nano has 0.5GB RAM -- swap needed to prevent OOM during dnf
dd if=/dev/zero of=/swapfile count=1024 bs=1MiB
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >>/etc/fstab

# Enable SSM agent dual-stack (IPv6)
IMDS_TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
AWS_REGION=$(curl -s -H "X-aws-ec2-metadata-token: $IMDS_TOKEN" "http://169.254.169.254/latest/meta-data/placement/region")
mkdir -p /etc/amazon/ssm
cat >/etc/amazon/ssm/amazon-ssm-agent.json <<SSM_CONFIG
{
    "Agent": {
        "Region": "$AWS_REGION",
        "UseDualStackEndpoint": true
    }
}
SSM_CONFIG
systemctl restart amazon-ssm-agent || true

# renovate: datasource=docker depName=vaultwarden/server versioning=docker
ENV_VAULTWARDEN_VERSION="1.37.0"
VAULTWARDEN_IMAGE="vaultwarden/server:$ENV_VAULTWARDEN_VERSION"

# Cloudflared repo + install
retry 3 curl -fsSL https://pkg.cloudflare.com/cloudflared.repo >/etc/yum.repos.d/cloudflared.repo
dnf install -y cloudflared docker
systemctl enable --now docker

# Fetch env from SSM
mkdir -p /etc/vaultwarden
retry 5 env AWS_USE_DUALSTACK_ENDPOINT=true aws ssm get-parameter --name "/${name}/env" --with-decryption --query Parameter.Value --output text >/etc/vaultwarden/.env

# Deploy-time config
cat >/etc/vaultwarden/backup.env <<BACKUP_ENV
R2_BUCKET=${r2_bucket_name}
VAULTWARDEN_IMAGE=$VAULTWARDEN_IMAGE
BACKUP_ENV

# Write cloudflared config
mkdir -p /etc/cloudflared

# Fetch tunnel secret from SSM
retry 5 env AWS_USE_DUALSTACK_ENDPOINT=true aws ssm get-parameter \
  --name "/${name}/tunnel-secret" --with-decryption \
  --query Parameter.Value --output text >/etc/cloudflared/tunnel_secret
chmod 600 /etc/cloudflared/tunnel_secret

cat >/etc/cloudflared/credentials.json <<TUNNEL_CONFIG
{
  "AccountTag": "${cloudflare_account_id}",
  "TunnelSecret": "$(cat /etc/cloudflared/tunnel_secret)",
  "TunnelID": "${tunnel_id}"
}
TUNNEL_CONFIG
chmod 600 /etc/cloudflared/credentials.json
rm /etc/cloudflared/tunnel_secret

cat >/etc/cloudflared/config.yml <<CLOUDFLARED_CONFIG
tunnel: ${tunnel_id}
credentials-file: /etc/cloudflared/credentials.json
ingress:
  - hostname: ${domain}
    service: http://localhost:8080
  - hostname: ssh.${domain}
    service: ssh://localhost:22
  - service: http_status:404
CLOUDFLARED_CONFIG

# Cloudflared runs as a dedicated non-root user
useradd -r -s /usr/sbin/nologin cloudflared
chown -R cloudflared:cloudflared /etc/cloudflared

# Cloudflared systemd service
cat >/etc/systemd/system/cloudflared.service <<UNIT
[Unit]
Description=Cloudflare Tunnel
After=network.target

[Service]
User=cloudflared
ExecStart=/usr/bin/cloudflared tunnel --config /etc/cloudflared/config.yml run
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT

systemctl enable --now cloudflared

# Mount EBS volume at /data
if ! mountpoint -q /data; then
  mkdir -p /data
  # Get instance ID for ec2 attach-volume
  INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $IMDS_TOKEN" "http://169.254.169.254/latest/meta-data/instance-id")
  # Attach EBS
  retry 10 env AWS_USE_DUALSTACK_ENDPOINT=true aws ec2 attach-volume \
    --volume-id "${ebs_volume_id}" \
    --instance-id "$INSTANCE_ID" \
    --device /dev/xvdf \
    --region "$AWS_REGION"
  # On Nitro, /dev/xvdf maps to NVMe; find by volume serial
  EBS_SERIAL=$(echo '${ebs_volume_id}' | tr -d '-')
  EBS_DEVICE=""
  for i in $(seq 1 30); do
    EBS_DEVICE=$(lsblk -o NAME,SERIAL 2>/dev/null | awk -v s="$EBS_SERIAL" '$2==s{print $1}' | head -1)
    [ -n "$EBS_DEVICE" ] && break
    sleep 2
  done
  if [ -z "$EBS_DEVICE" ]; then
    echo "ERROR: EBS device not found after attach" >&2
    exit 1
  fi
  if ! lsblk -f "/dev/$EBS_DEVICE" | grep -q ext4; then
    echo "Formatting /dev/$EBS_DEVICE as ext4..."
    mkfs.ext4 -F "/dev/$EBS_DEVICE"
  fi
  mount "/dev/$EBS_DEVICE" /data
  echo "UUID=$(blkid -s UUID -o value /dev/$EBS_DEVICE) /data ext4 defaults,nofail 0 2" >>/etc/fstab
fi

mkdir -p /data/vaultwarden /data/scripts /data/tmp

# Write instance scripts
cat >/data/scripts/backup.sh <<'SCRIPT'
${backup_script}
SCRIPT
chmod +x /data/scripts/backup.sh

cat >/data/scripts/restore.sh <<'SCRIPT'
${restore_script}
SCRIPT
chmod +x /data/scripts/restore.sh

cat >/data/scripts/AWS_SpotTerminationNotifier.sh <<'SCRIPT'
${spot_term_script}
SCRIPT
chmod +x /data/scripts/AWS_SpotTerminationNotifier.sh

cat >/data/scripts/r2-config.sh <<'SCRIPT'
${r2_config_script}
SCRIPT
chmod +x /data/scripts/r2-config.sh

cat >/etc/systemd/system/spot-termination-notifier.service <<UNIT
[Unit]
Description=AWS Spot Termination Notifier
After=network.target

[Service]
ExecStart=/data/scripts/AWS_SpotTerminationNotifier.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
UNIT
systemctl enable --now spot-termination-notifier

# Restore from latest backup if vaultwarden data directory is empty
if ! ls -A /data/vaultwarden 2>/dev/null | grep -q .; then
  echo "Vaultwarden data directory empty -- attempting restore from latest R2 backup"
  /data/scripts/restore.sh --latest || true
fi

# Start vaultwarden
# shellcheck source=/dev/null
source /etc/vaultwarden/backup.env
retry 3 docker run -d \
  --name vaultwarden \
  --restart unless-stopped \
  -p 127.0.0.1:8080:80 \
  -v /data/vaultwarden:/data \
  --env-file /etc/vaultwarden/.env \
  --health-cmd "curl -sf http://localhost:80/alive || exit 1" \
  --health-interval 30s \
  --health-timeout 5s \
  --health-retries 3 \
  "$VAULTWARDEN_IMAGE"

# Backup timer: daily at 02:00
cat >/etc/systemd/system/vaultwarden-backup.service <<UNIT
[Unit]
Description=Vaultwarden backup to R2

[Service]
Type=oneshot
ExecStart=/data/scripts/backup.sh
StandardOutput=append:/var/log/vaultwarden-backup.log
StandardError=append:/var/log/vaultwarden-backup.log
UNIT

cat >/etc/systemd/system/vaultwarden-backup.timer <<UNIT
[Unit]
Description=Daily vaultwarden backup

[Timer]
OnCalendar=*-*-* 02:00:00
Persistent=true

[Install]
WantedBy=timers.target
UNIT

systemctl enable --now vaultwarden-backup.timer
