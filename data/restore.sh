#!/bin/bash
set -euo pipefail

VAULTWARDEN_DIR=/data/vaultwarden
RESTORE_TMP=/data/tmp

# Deploy-time config from user-data
# shellcheck source=/dev/null
[ -f /etc/vaultwarden/backup.env ] && source /etc/vaultwarden/backup.env
R2_BUCKET="${R2_BUCKET:-}"

if [ $# -ne 1 ]; then
  echo "Usage: $0 {TIMESTAMP|--latest}"
  echo "  TIMESTAMP format: YYYYMMDD-HHMMSS"
  echo "  --latest    Restore from most recent backup in R2"
  if [ -n "${R2_BUCKET}" ]; then
    echo "  List available backups: aws s3 ls s3://${R2_BUCKET}/ --endpoint-url <R2_ENDPOINT_URL>"
  fi
  exit 1
fi

if [ -z "${R2_BUCKET:-}" ]; then
  echo "R2_BUCKET must be set in /etc/vaultwarden/backup.env"
  exit 1
fi

# shellcheck source=/dev/null
. /data/scripts/r2-config.sh
r2_load_config

if [ "$1" = "--latest" ]; then
  LATEST_KEY=$(aws s3 ls "s3://${R2_BUCKET}/" --endpoint-url "$R2_ENDPOINT_URL" | sort | tail -1 | awk '{print $4}')
  if [ -z "$LATEST_KEY" ]; then
    echo "No backups found in s3://${R2_BUCKET}/"
    exit 1
  fi
  BACKUP_TIMESTAMP="${LATEST_KEY%-bitwarden-backup.tar.gz}"
else
  BACKUP_TIMESTAMP=$1
fi

BACKUP_KEY="${BACKUP_TIMESTAMP}-bitwarden-backup.tar.gz"

if ! aws s3 ls "s3://${R2_BUCKET}/${BACKUP_KEY}" --endpoint-url "$R2_ENDPOINT_URL" > /dev/null 2>&1; then
  echo "Backup ${BACKUP_TIMESTAMP} not found in s3://${R2_BUCKET}/"
  exit 1
fi

aws s3 cp "s3://${R2_BUCKET}/${BACKUP_KEY}" "${RESTORE_TMP}/" --endpoint-url "$R2_ENDPOINT_URL"

docker stop vaultwarden || true
trap 'docker start vaultwarden 2>/dev/null || docker run -d \
  --name vaultwarden \
  --restart unless-stopped \
  -p 127.0.0.1:8080:80 \
  -v /data/vaultwarden:/data \
  --env-file /etc/vaultwarden/.env \
  "${VAULTWARDEN_IMAGE:-vaultwarden/server:latest}" || true' EXIT

EXTRACT_DIR="${RESTORE_TMP}/extract-${BACKUP_TIMESTAMP}"
mkdir -p "$EXTRACT_DIR"
tar xzf "${RESTORE_TMP}/${BACKUP_KEY}" -C "$EXTRACT_DIR"
rm -rf "${VAULTWARDEN_DIR}.old"
[ -d "$VAULTWARDEN_DIR" ] && mv "$VAULTWARDEN_DIR" "${VAULTWARDEN_DIR}.old"
mv "$EXTRACT_DIR" "$VAULTWARDEN_DIR"
rm -rf "${VAULTWARDEN_DIR}.old"
rm "${RESTORE_TMP}/${BACKUP_KEY}"

echo "Restore from ${BACKUP_TIMESTAMP} complete"
