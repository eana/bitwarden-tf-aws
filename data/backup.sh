#!/bin/bash
set -euo pipefail

LOCK_FILE=/var/lock/bitwarden-backup.lock
exec 200>"$LOCK_FILE"
flock -n 200 || { echo "Backup already running -- exiting"; exit 1; }

VAULTWARDEN_DIR=/data/vaultwarden
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_TMP=/data/tmp

# Deploy-time config from user-data
# shellcheck source=/dev/null
[ -f /etc/vaultwarden/backup.env ] && source /etc/vaultwarden/backup.env
R2_BUCKET="${R2_BUCKET:-}"

if [ -z "${R2_BUCKET:-}" ]; then
  echo "R2_BUCKET must be set in /etc/vaultwarden/backup.env"
  exit 1
fi

# shellcheck source=/dev/null
. /data/scripts/r2-config.sh
r2_load_config

mkdir -p "$BACKUP_TMP"
docker stop vaultwarden || true
trap 'docker start vaultwarden 2>/dev/null || docker run -d \
  --name vaultwarden \
  --restart unless-stopped \
  -p 127.0.0.1:8080:80 \
  -v /data/vaultwarden:/data \
  --env-file /etc/vaultwarden/.env \
  "${VAULTWARDEN_IMAGE:-vaultwarden/server:latest}" || true' EXIT

tar czf "${BACKUP_TMP}/bitwarden-backup-${TIMESTAMP}.tar.gz" -C "$VAULTWARDEN_DIR" .

aws s3 cp "${BACKUP_TMP}/bitwarden-backup-${TIMESTAMP}.tar.gz" "s3://${R2_BUCKET}/${TIMESTAMP}-bitwarden-backup.tar.gz" --endpoint-url "$R2_ENDPOINT_URL"

rm "${BACKUP_TMP}/bitwarden-backup-${TIMESTAMP}.tar.gz"

echo "Backup ${TIMESTAMP} complete"
