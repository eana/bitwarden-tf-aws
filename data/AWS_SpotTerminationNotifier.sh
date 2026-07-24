#!/bin/bash
# AWS Instance Termination Notice Handler
# Based on: https://blog.fugue.co/2015-01-06-spot-termination-notices.html

set -euo pipefail

TOKEN_URL="http://169.254.169.254/latest/api/token"
META_URL="http://169.254.169.254/latest/meta-data/spot/termination-time"

while true; do
  TOKEN=$(curl -s -X PUT "$TOKEN_URL" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" -H "X-aws-ec2-metadata-token: $TOKEN" "$META_URL")
  if [ "$STATUS" != "404" ]; then
    echo "$(date +"%F_%T"): Spot termination notice received, backing up and stopping vaultwarden" | tee -a /var/log/spot-termination.log
    /data/scripts/backup.sh >> /var/log/spot-termination.log 2>&1 || true
    docker stop vaultwarden || true
    break
  fi
  sleep 5
done
