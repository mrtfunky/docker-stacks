#!/bin/bash

exit 0

# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

$SCRIPT_DIR/stop_stacks.sh
$SCRIPT_DIR/backup_stacks.sh

echo "Poweroff for 8 hours"
sudo /usr/sbin/rtcwake -m off -s 28800
