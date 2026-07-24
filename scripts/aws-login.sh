#!/usr/bin/env bash
# shellcheck disable=SC2046
set -euo pipefail

#
# Generate temporary AWS session token via STS with MFA.
#
# Requires an IAM user with MFA enabled and the following permissions:
#   - sts:GetSessionToken
#   - iam:ListMFADevices
#

# -- Constants ----------------------------------------------------------------
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly RESET='\033[0m'

# -- Helper functions ---------------------------------------------------------
function have_program {
  local prog=$1

  if ! hash "${prog}" >/dev/null 2>&1; then
    echo -e "${RED}Unable to find '${prog}', Is it installed?${RESET}"
    return 1
  fi

  return 0
}

function sanity_check {
  local have_error=0

  have_program aws || have_error=1

  return "$have_error"
}

# -- Usage --------------------------------------------------------------------
if [ $# -ne 2 ]; then
  echo -e "Usage: $0 <USERNAME> <MFA_TOKEN_CODE>"
  echo -e "Where:"
  echo -e "   <USERNAME> = The IAM username for which to get a temp session token"
  echo -e "   <MFA_TOKEN_CODE> = Code from virtual MFA device"
  exit 2
fi

# -- Environment variables ----------------------------------------------------
AWS_USER_PROFILE="temp"
AWS_2AUTH_PROFILE="default"
MFA_TOKEN_CODE=$2
DURATION=43200

# -- Main ---------------------------------------------------------------------
function main {
  echo -e "${YELLOW}Starting Sanity check.${RESET}"
  if ! sanity_check; then
    echo -e "${RED}Sanity check failed.${RESET}"
    exit 1
  fi
  echo -e "${GREEN}Sanity check passed.${RESET}"

  ARN_OF_MFA=$(aws --profile "${AWS_USER_PROFILE}" iam list-mfa-devices --user-name "$1" --output text | awk '{print $3}')

  local have_error=0

  read -r AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN <<< \
    $(aws --profile "${AWS_USER_PROFILE}" sts get-session-token \
      --duration "${DURATION}" \
      --serial-number "${ARN_OF_MFA}" \
      --token-code "${MFA_TOKEN_CODE}" \
      --output text | awk '{ print $2, $4, $5 }') || have_error=1

  if [ -n "${DEBUG+x}" ]; then
    echo "AWS-CLI Profile: ${AWS_2AUTH_PROFILE}"
    echo "MFA ARN: ${ARN_OF_MFA}"
    echo "MFA Token Code: ${MFA_TOKEN_CODE}"

    echo "AWS_ACCESS_KEY_ID: ${AWS_ACCESS_KEY_ID}"
    echo "AWS_SECRET_ACCESS_KEY: <redacted>"
    echo "AWS_SESSION_TOKEN: <redacted>"
  fi

  if [ -z "${AWS_ACCESS_KEY_ID}" ]; then
    have_error=1
  fi

  if [ "$have_error" -eq 0 ]; then
    aws --profile "${AWS_2AUTH_PROFILE}" configure set aws_access_key_id "${AWS_ACCESS_KEY_ID}" || have_error=1
    aws --profile "${AWS_2AUTH_PROFILE}" configure set aws_secret_access_key "${AWS_SECRET_ACCESS_KEY}" || have_error=1
    aws --profile "${AWS_2AUTH_PROFILE}" configure set aws_session_token "${AWS_SESSION_TOKEN}" || have_error=1
  fi

  if [ "${have_error}" -eq "0" ]; then
    echo -e "PROFILE: ${YELLOW}${AWS_2AUTH_PROFILE}${RESET}"
    echo -e "${GREEN}Temporary Creds written in ${YELLOW}~/.aws/credentials.${RESET}"
  else
    echo -e "${RED}ERROR retrieving credentials from AWS.${RESET}"
  fi

  exit "${have_error}"
}

main "$@"
