#!/bin/bash

NAME="vaultwarden"

# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source $SCRIPT_DIR/../scripts/backup_lib.sh

BACKUP_DIR=/nfs_shares/backup/vaultwarden
if [ "$1" = "--test" ]; then
    BACKUP_DIR=$(pwd)/backup
fi

COMPOSE_FILE=$SCRIPT_DIR/docker-compose.yml
BACKUP_UID=1026
BACKUP_GID=100

echo ""
echo "#################################"
echo "### Starting $NAME backup"
echo "#################################"
echo ""

# Backup volumes
create_archive vaultwarden_data    vaultwarden_data_backup
# create_archive /home/karl/docker/vaultwarden/data    vaultwarden_data_backup

# Clean old backups
delete_old_backups 7 $BACKUP_DIR

echo ""
echo "#################################"
echo "###        DONE $NAME"
echo "#################################"
