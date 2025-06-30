#!/bin/bash
# shellcheck disable=SC2154
set -exuo pipefail

# Determine the region
AWS_DEFAULT_REGION="$(/opt/aws/bin/ec2-metadata -z | sed 's/placement: \(.*\).$/\1/')"
export AWS_DEFAULT_REGION

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

# Allocate 1G disk space to be used as memory with a swap file to prevent errors like:
# Error downloading packages:
# gobject-introspection-1.56.1-1.amzn2.x86_64: [Errno 5] [Errno 12] Cannot allocate memory
dd if=/dev/zero of=/swapfile count=1024 bs=1MiB
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
cat >> /etc/fstab << 'EOF'
/swapfile none swap sw 0 0
EOF

# Attach the ENI
instance_id="$(/opt/aws/bin/ec2-metadata -i | cut -d' ' -f2)"
retry 10 aws ec2 attach-network-interface \
    --instance-id "$instance_id" \
    --device-index 1 \
    --network-interface-id "${eni_id}"

# Wait for network initialization
sleep 10

# Waiting for network connection
curl --retry 10 http://www.example.com

# Attach the EBS volume
retry 10 aws ec2 attach-volume \
    --volume-id "${volume_id}" \
    --instance-id "$instance_id" \
    --device /dev/xvdf

# Wait for the EBS volume to be attached
sleep 10

# Mount the EBS volume
mkdir -p /home/ec2-user/bitwarden
chown ec2-user:ec2-user /home/ec2-user/bitwarden
retry 10 lsblk -f /dev/xvdf
if ! lsblk -f /dev/xvdf | grep -E "xvdf|nvme1n1" | grep -q ext4; then
  echo "The EBS volume is not formatted. Formatting it..."
  mkfs.ext4 /dev/xvdf
fi
mount /dev/xvdf /home/ec2-user/bitwarden

# Upgrade python
yum remove -y python3
amazon-linux-extras install -y python3.8
ln -s /usr/bin/python3.8 /usr/bin/python3
ln -s /usr/bin/pip3.8 /usr/bin/pip3

# Install docker
yum update -y
yum install -y docker
usermod -a -G docker ec2-user
systemctl start docker.service

# Create the directories where the configuration files will be stored
mkdir -p /home/ec2-user/conf/{compose,traefik,scripts}

# Install docker-compose
# renovate: datasource=github-releases depName=docker/compose versioning=semver
export ENV_DOCKER_COMPOSE_VERSION="v2.38.0"
curl -L "https://github.com/docker/compose/releases/download/$ENV_DOCKER_COMPOSE_VERSION/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose
chmod a+x /usr/local/bin/docker-compose

# Install mozilla sops
# renovate: datasource=github-releases depName=mozilla/sops versioning=semver
export ENV_SOPS_VERSION="v3.10.2"
curl -L "https://github.com/mozilla/sops/releases/download/$ENV_SOPS_VERSION/sops-$(echo $ENV_SOPS_VERSION | cut -c2-).x86_64.rpm" -o "/tmp/sops-$(echo $ENV_SOPS_VERSION | cut -c2-).x86_64.rpm"
rpm -i "/tmp/sops-$(echo $ENV_SOPS_VERSION | cut -c2-).x86_64.rpm"
rm -f "/tmp/sops-$(echo $ENV_SOPS_VERSION | cut -c2-).x86_64.rpm"

# Get the secrets
aws s3 cp "s3://${resources_bucket}/${bitwarden_env_key}" /home/ec2-user/conf/compose/env.enc
/usr/bin/sops -d /home/ec2-user/conf/compose/env.enc > /home/ec2-user/conf/compose/.env
rm -f /home/ec2-user/conf/compose/env.enc

# Configure docker-compose
yum install -y jq
mkdir -p /home/ec2-user/bitwarden/{bitwarden-data,mysql}
mkdir -p /home/ec2-user/bitwarden/traefik/{letsencrypt,log}
touch -f /home/ec2-user/bitwarden/traefik/log/access.log
touch -f /home/ec2-user/bitwarden/bitwarden-data/bitwarden.log

aws s3 cp "s3://${resources_bucket}/${bitwarden_compose_key}" /home/ec2-user/conf/compose/docker-compose.yml
aws s3 cp "s3://${resources_bucket}/${traefik-dynamic_key}" /home/ec2-user/conf/traefik/dynamic.yaml

# The backup script
aws s3 cp "s3://${resources_bucket}/${backup_script_key}" /home/ec2-user/conf/scripts/backup.sh
chmod a+x /home/ec2-user/conf/scripts/backup.sh
cat >> /etc/cron.d/bitwarden-backup << 'EOF'
${backup_schedule} root /home/ec2-user/conf/scripts/backup.sh > /dev/null 2>&1
EOF

# The restore script
aws s3 cp "s3://${resources_bucket}/${restore_script_key}" /home/ec2-user/conf/scripts/restore.sh
chmod a+x /home/ec2-user/conf/scripts/restore.sh

# Install fail2ban
amazon-linux-extras install epel -y
yum -y install fail2ban
systemctl restart fail2ban

aws s3 cp "s3://${resources_bucket}/${fail2ban_filter_key}" /etc/fail2ban/filter.d/bitwarden.local
aws s3 cp "s3://${resources_bucket}/${fail2ban_jail_key}" /etc/fail2ban/jail.d/bitwarden.local
aws s3 cp "s3://${resources_bucket}/${admin_fail2ban_filter_key}" /etc/fail2ban/filter.d/bitwarden-admin.local
aws s3 cp "s3://${resources_bucket}/${admin_fail2ban_jail_key}" /etc/fail2ban/jail.d/bitwarden-admin.local
systemctl reload fail2ban

# Logrotate
aws s3 cp "s3://${resources_bucket}/${bitwarden-logrotate_key}" /etc/logrotate.d/bitwarden
aws s3 cp "s3://${resources_bucket}/${traefik-logrotate_key}" /etc/logrotate.d/traefik

# Gracefully shutdown the app if the instance is scheduled for termination
aws s3 cp "s3://${resources_bucket}/${AWS_SpotTerminationNotifier_script_key}" /home/ec2-user/conf/scripts/AWS_SpotTerminationNotifier.sh
chmod a+x /home/ec2-user/conf/scripts/AWS_SpotTerminationNotifier.sh
screen -dm -S AWS_SpotTerminationNotifier /home/ec2-user/conf/scripts/AWS_SpotTerminationNotifier.sh

# Add AWS EC2 Spot Instance Pricing Script
aws s3 cp "s3://${resources_bucket}/${AWS_SpotInstancePricing_script_key}" /home/ec2-user/conf/scripts/AWS_SpotInstancePricing.py
chmod a+x /home/ec2-user/conf/scripts/AWS_SpotInstancePricing.py
pip3 install boto3 --no-color

# Pull all the docker images
docker-compose -f /home/ec2-user/conf/compose/docker-compose.yml pull -q

# Fix permissions
chown ec2-user:ec2-user -R /home/ec2-user/conf
chown ec2-user:ec2-user -R /home/ec2-user/bitwarden/{bitwarden-data,mysql,traefik}

# Start bitwarden
echo "Starting bitwarden in 2 minutes"
sleep 120 # wait 2 minutes for other resources to come up
docker-compose -f /home/ec2-user/conf/compose/docker-compose.yml --env-file /home/ec2-user/conf/compose/.env up -d

# Switch the default route to eth1
ip route del default dev eth0
