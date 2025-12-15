#!/bin/sh

# Check if script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Please use sudo."
    exit 1
fi

cp docker-stacks.service /etc/systemd/system
systemctl daemon-reload
systemctl enable docker-stacks
