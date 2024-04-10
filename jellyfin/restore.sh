#!/bin/bash

BACKUP_FOLDER=/home/karl/backups/jellyfin

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

clear_vloume jellyfin_data
restore_volume jellyfin_data ${BACKUP_FOLDER}/jellyfin_data_backup_latest.tar.gz
