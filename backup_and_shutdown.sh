#!/bin/bash

# exit 0

# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

$SCRIPT_DIR/borgbackup/borgbackup_volumes.sh

echo "Poweroff for 7 hours"
sudo /usr/sbin/rtcwake -m off -s 25200
