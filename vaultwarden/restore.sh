#!/bin/bash

BACKUP_DIR=$(pwd)/backup

restore_volume () {

    volume_name=$1
    archive_name=$2
    
    echo "Restoring $volume_name from $archive_name"

    docker run  --rm\
                -v $archive_name:/archive.tar.gz:ro \
                -v $volume_name:/restore_target \
                alpine sh\
                -c "tar xf /archive.tar.gz -C /restore_target ."

    echo -e "DONE"
}

clear_vloume() {
    volume_name=$1

    echo "Clearing $volume_name"

    docker run --rm \
        -v $volume_name:/restore_target alpine sh \
        -c "rm -Rf /restore_target/*"

    echo -e "DONE"
}

clear_vloume vaultwarden_data
restore_volume vaultwarden_data ${BACKUP_DIR}/vaultwarden_data_backup_latest.tar.gz
