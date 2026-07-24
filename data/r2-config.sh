# Loads R2 creds from /etc/vaultwarden/.env and exports them

r2_load_config() {
  if [ ! -f /etc/vaultwarden/.env ]; then
    echo "R2_ENDPOINT_URL, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY must be set in /etc/vaultwarden/.env"
    return 1
  fi
  R2_ENDPOINT_URL=$(grep '^R2_ENDPOINT_URL=' /etc/vaultwarden/.env | tail -1 | cut -d= -f2-)
  R2_ACCESS_KEY_ID=$(grep '^R2_ACCESS_KEY_ID=' /etc/vaultwarden/.env | tail -1 | cut -d= -f2-)
  R2_SECRET_ACCESS_KEY=$(grep '^R2_SECRET_ACCESS_KEY=' /etc/vaultwarden/.env | tail -1 | cut -d= -f2-)
  if [ -z "${R2_ENDPOINT_URL}" ] || [ -z "${R2_ACCESS_KEY_ID}" ] || [ -z "${R2_SECRET_ACCESS_KEY}" ]; then
    echo "R2_ENDPOINT_URL, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY must be set in /etc/vaultwarden/.env"
    return 1
  fi
  export AWS_ACCESS_KEY_ID=$R2_ACCESS_KEY_ID
  export AWS_SECRET_ACCESS_KEY=$R2_SECRET_ACCESS_KEY
  export AWS_DEFAULT_REGION=auto
  export R2_ENDPOINT_URL=$R2_ENDPOINT_URL
}
