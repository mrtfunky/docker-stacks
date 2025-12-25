#!/bin/bash

# Description: this script installs BorgBackup and its dependencies

# Check if script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Please use sudo."
    exit 1
fi

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Import borgbackup_config.sh
source "${SCRIPT_DIR}/borgbackup_config.sh"

# Installation destination
INSTALL_DIR="/opt/borgbackup"

# Clean up any previous installation
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

# Create a README file in the installation directory
echo "Karls BorgBackup Installation" > "$INSTALL_DIR/README"
echo "======================" >> "$INSTALL_DIR/README"
echo "" >> "$INSTALL_DIR/README"

install -D ${SCRIPT_DIR}/borgbackup.sh         "$INSTALL_DIR/bin/borgbackup.sh"
install -D ${SCRIPT_DIR}/backup                "$INSTALL_DIR/bin/backup"
install -D ${SCRIPT_DIR}/status                "$INSTALL_DIR/bin/status"
install -D ${SCRIPT_DIR}/today                 "$INSTALL_DIR/bin/today"
install -D ${SCRIPT_DIR}/borg_helpers.sh       "$INSTALL_DIR/bin/borg_helpers.sh"
install -D ${SCRIPT_DIR}/borgbackup_config.sh  "$INSTALL_DIR/bin/borgbackup_config.sh"
install -D ${SCRIPT_DIR}/excludes.txt          "$INSTALL_DIR/bin/excludes.txt"

# Install docker-compose.yml files for each stack
for stack in "${STASKS_TO_STOP[@]}"; do
    src="${SCRIPT_DIR}/../${stack}/docker-compose.yml"
    dest="${INSTALL_DIR}/${stack}/docker-compose.yml"

    # Install the docker-compose.yml file
    install -D "$src" "$dest" || { echo "Error: failed to install $src"; exit 1; }
    echo "Installed ${dest}"
    echo "${dest}" >> "$INSTALL_DIR/README"

    # Install the .env file if it exists
    if [ -f "${SCRIPT_DIR}/../${stack}/.env" ]; then
        install -D "${SCRIPT_DIR}/../${stack}/.env" "${INSTALL_DIR}/${stack}/.env" || { echo "Error: failed to install .env for $stack"; exit 1; }
        echo "Installed ${dest} .env"
        echo "${dest} .env" >> "$INSTALL_DIR/README"
    fi
done


# Check if installation was successful
if [ $? -ne 0 ]; then
    echo "Error: Installation failed."
    exit 1
fi

echo "BorgBackup installed successfully in $INSTALL_DIR"