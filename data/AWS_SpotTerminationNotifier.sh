#!/bin/bash
# AWS Instance Termination Notice Handler
# Based on: https://blog.fugue.co/2015-01-06-spot-termination-notices.html

set -euo pipefail

while true; do
    # get meta-data HTTP headers
    HEADER=$(curl -Is http://169.254.169.254/latest/meta-data/spot/termination-time)

    # HTTP 404 - not marked for termination
    if [ -z $(echo "$HEADER" | head -1 | grep 404 | cut -d \  -f 2) ]; then
        echo "Running shutdown hook."
        docker-compose -f /home/ec2-user/bitwarden/compose/docker-compose.yml down
        /home/ec2-user/bitwarden/scripts/backup.sh
        break
    else
        # Spot instance not yet marked for termination.
        sleep 5
    fi
done
