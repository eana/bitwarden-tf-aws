#!/bin/bash
# shellcheck disable=SC2154
set -euo pipefail

# -- Constants for coloured output --------------------------------------------
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly RESET='\033[0m'

# -- Helper functions ---------------------------------------------------------
function usage {
    # Print out the usage
    cat <<EOT
$0 DATE
Restores a backup from the given date.
    DATE - The date format is YYYYMMDD
EOT
}

function have_program {
    local program=$1

    if ! hash "$program" > /dev/null 2>&1; then
        echo -e "$RED"Unable to find "'$program'", Is it installed?"$RESET"
        return 1
    fi

    return 0
}

function sanity_check {
    local have_error=0

    have_program aws || have_error=1

    return $have_error
}

function check_backup_exists {
    local backup_date=$1

    if ! aws s3 ls s3://"${bucket}"/"$backup_date"_bitwarden-backup.tar.gz > /dev/null 2>&1; then
        return 1
    fi

    return 0
}

function download_backup_if_exists {
    local backup_date=$1
    local backup_dir=$2

    if check_backup_exists "$backup_date"; then
        echo -e "$YELLOW"Downloading backup from S3..."$RESET"
        aws s3 cp --quiet s3://"${bucket}"/"$backup_date"_bitwarden-backup.tar.gz "$backup_dir"/bitwarden-backup.tar.gz
    fi
}

function untar_backup {
    local backup_dir=$1
    local dest_dir=$2

    if [ -f "$backup_dir/bitwarden-backup.tar.gz" ]; then
        # Decompress the backup file
        echo -e "$YELLOW"Decompress the backup file..."$RESET"
        tar xzf "$backup_dir/bitwarden-backup.tar.gz" -C "$dest_dir"
    fi
}

function restore_backup {
    local backup_date=$1
    local backup_dir=$2

    mkdir -p "$backup_dir"
    download_backup_if_exists "$backup_date" "$backup_dir"

    # Stop the app
    echo -e "$YELLOW"Stopping the app..."$RESET"
    /usr/local/bin/docker-compose -f /home/ec2-user/conf/compose/docker-compose.yml down > /dev/null 2>&1

    # Synchronize the backup content with the application directory
    echo -e "$YELLOW"Synchronize the backup content with the application directory..."$RESET"
    sudo touch -f /home/ec2-user/bitwarden/restore.log
    sudo chown ec2-user:ec2-user /home/ec2-user/bitwarden/restore.log
    rsync -av --delete "$backup_dir"/bitwarden/{bitwarden-data,mysql,traefik} /home/ec2-user/bitwarden --log-file=/home/ec2-user/bitwarden/restore.log > /dev/null 2>&1

    echo -e "$YELLOW"File transfer log: /home/ec2-user/bitwarden/restore.log"$RESET"

    # Start the app
    echo -e "$YELLOW"Starting the app..."$RESET"
    /usr/local/bin/docker-compose -f /home/ec2-user/conf/compose/docker-compose.yml up -d > /dev/null 2>&1
}

function cleanup {
    local backup_dir=$1

    if [ -d "$backup_dir" ]; then
        rm -rf "$backup_dir"
    fi
}

# -- Main ---------------------------------------------------------------------
function main {

    if [ "$#" -ne 1 ]; then
        echo -e "$RED"Incorrect number of arguments"$RESET"
        usage
        exit 1
    fi

    local backup_date=$1
    local backup_dir=/tmp/bitwarden-backup-"$backup_date"

    local temp_dir
    temp_dir=$(mktemp -d)

    echo -e "$YELLOW"Starting Sanity check."$RESET"
    if ! sanity_check; then
        echo -e "$RED"Sanity check failed."$RESET"
        exit 1
    fi
    echo -e "$GREEN"Sanity check passed."$RESET"

    if ! check_backup_exists "$backup_date"; then
        echo -e "$RED"Backup for "$backup_date" does not exist."$RESET"
        exit 1
    fi

    download_backup_if_exists "$backup_date" "$backup_dir"

    echo -e "$YELLOW"Starting the restore."$RESET"
    untar_backup "$backup_dir" "$temp_dir"
    restore_backup "$backup_date" "$temp_dir"

    echo -e "$YELLOW"Cleaning up."$RESET"
    cleanup "$backup_dir"
    cleanup "$temp_dir"

    echo -e "$GREEN"All Done!"$RESET"
}

main "$@"
