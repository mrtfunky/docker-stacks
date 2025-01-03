#!/bin/bash

# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APP_NAME=audiobookshelf

source $SCRIPT_DIR/../scripts/backup_lib.sh

# BACKUP_DIR=$(pwd)/backup
BACKUP_DIR=/nfs_shares/backup/${APP_NAME}

COMPOSE_FILE=$SCRIPT_DIR/docker-compose.yml
BACKUP_UID=1026
BACKUP_GID=100

echo ""
echo "#################################"
echo "### Starting ${APP_NAME} backup"
echo "#################################"
echo ""

# Backup volumes
create_archive ${APP_NAME}_config         ${APP_NAME}_config_backup
create_archive ${APP_NAME}_metadata       ${APP_NAME}_metadata_backup

# Clean old backups
delete_old_backups 4 $BACKUP_DIR

echo ""
echo "#################################"
echo "###        DONE ${APP_NAME}"
echo "#################################"
