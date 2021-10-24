#!/bin/bash
# shellcheck disable=SC2154
set -exuo pipefail

# Determine the region
AWS_DEFAULT_REGION="$(/opt/aws/bin/ec2-metadata -z | sed 's/placement: \(.*\).$/\1/')"
export AWS_DEFAULT_REGION

# Attach the ENI
instance_id="$(/opt/aws/bin/ec2-metadata -i | cut -d' ' -f2)"
aws ec2 attach-network-interface \
    --instance-id "$instance_id" \
    --device-index 1 \
    --network-interface-id "${eni_id}"

# Wait for network initialization
sleep 10

# Waiting for network connection
curl --retry 10 http://www.example.com

# Restart the SSM agent
systemctl restart amazon-ssm-agent.service

# Attach the EBS volume
aws ec2 attach-volume \
    --volume-id "${volume_id}" \
    --instance-id "$instance_id" \
    --device /dev/xvdf

# Wait for the EBS volume to be attached
sleep 10

# Mount the EBS volume
mkdir -p /home/ec2-user/bitwarden
# TODO: check if the partition is formatted or not (lsblk -f)
mount /dev/xvdf /home/ec2-user/bitwarden

# Install docker
yum update
yum install -y docker
usermod -a -G docker ec2-user
systemctl start docker.service

# Install docker-compose
curl -L "https://github.com/docker/compose/releases/download/v2.0.1/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose
chmod a+x /usr/local/bin/docker-compose

# Install mozilla sops
curl -L "https://github.com/mozilla/sops/releases/download/v3.7.1/sops-3.7.1-1.x86_64.rpm" -o /tmp/sops-3.7.1-1.x86_64.rpm
rpm -i /tmp/sops-3.7.1-1.x86_64.rpm
rm -f /tmp/sops-3.7.1-1.x86_64.rpm

# Get the secrets
export SOPS_KMS_ARN="${kms_key_arn}"
aws s3 cp "s3://${resources_bucket}/${bitwarden_env_key}" /home/ec2-user/bitwarden/compose/.env
sops -d -i /home/ec2-user/bitwarden/compose/.env

# Configure docker-compose
yum install -y jq
mkdir -p /home/ec2-user/bitwarden/{compose,letsencrypt,bitwarden-data,mysql,scripts}
touch -f /home/ec2-user/bitwarden/bitwarden-data/bitwarden.log
aws s3 cp "s3://${resources_bucket}/${bitwarden_compose_key}" /home/ec2-user/bitwarden/compose/docker-compose.yml

# backups
aws s3 cp "s3://${resources_bucket}/${backup_script_key}" /home/ec2-user/bitwarden/scripts/backup.sh
chmod a+x /home/ec2-user/bitwarden/scripts/backup.sh
cat >> /etc/cron.d/bitwarden-backup << 'EOF'
${backup_schedule} root /home/ec2-user/bitwarden/scripts/backup.sh
EOF

# restore

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
aws s3 cp "s3://${resources_bucket}/${logrotate_key}" /etc/logrotate.d/bitwarden

# Fix permissions
chown ec2-user:ec2-user -R /home/ec2-user/bitwarden/{compose,scripts}

# Switch the default route to eth1
ip route del default dev eth0
