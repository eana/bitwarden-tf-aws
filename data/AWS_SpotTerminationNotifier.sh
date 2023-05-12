#!/bin/bash
# AWS Instance Termination Notice Handler
# Based on: https://blog.fugue.co/2015-01-06-spot-termination-notices.html

set -euo pipefail

while true; do
    if [ -z "$(curl -Is http://169.254.169.254/latest/meta-data/spot/termination-time | head -1 | grep 404 | cut -d ' ' -f 2)" ]; then
        echo "$(date +"%F_%T"): Running shutdown hook!" | sudo tee -a /home/ec2-user/bitwarden/AWS_SpotTerminationNotifier.log
        sudo /home/ec2-user/conf/scripts/backup.sh
        break
    else
        # Spot instance not yet marked for termination.
        sleep 5
    fi
done
