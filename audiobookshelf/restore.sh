#!/bin/bash

# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APP_NAME=audiobookshelf

BACKUP_FOLDER=${SCRIPT_DIR}/backup
# BACKUP_FOLDER=${SCRIPT_DIR}/${APP_NAME}

restore_volume () {
    date_tag=$(date '+%Y-%m-%d_%H-%M-%S')
    
    volume_name=$1
    archive_name=$2
    
    echo -n "Restoring $volume_name"

    docker run  --rm\
                -v $archive_name:/archive.tar.gz:ro \
                -v $volume_name:/restore_target \
                ubuntu \
                tar xf /archive.tar.gz -C /restore_target .

    echo -e "\t\t\tDONE"
}

clear_vloume() {
    volume_name=$1

    echo -n "Clearing $volume_name"

    docker run --rm \
        -v $1:/restore_target ubuntu bash \
        -c "rm -Rf /restore_target/*"

    echo -e "\t\t\tDONE"
}

clear_vloume   ${APP_NAME}_config
restore_volume ${APP_NAME}_config     ${BACKUP_FOLDER}/${APP_NAME}_config_backup_latest.tar.gz

clear_vloume   ${APP_NAME}_metadata
restore_volume ${APP_NAME}_metadata   ${BACKUP_FOLDER}/${APP_NAME}_metadata_backup_latest.tar.gz
