#!/bin/bash

# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Rository base path
REPO_PATH=/nfs_shares/backup/borgbackup
# Repostory base path for testing
#REPO_PATH=${SCRIPT_DIR}/borgbackup_test

# Initialize repository if does not exist
# Arguments:
#   1. Volume name
initialize_repo() {
    local volume_name=$1

    # Exit if the repository already exists
    if [ -d ${REPO_PATH}/${volume_name} ]; then
        echo "Repository already exists at ${REPO_PATH}/${volume_name}. Skipping initialization."
        return
    fi

    echo "Creating Borg repository at ${repository_path}..."
    mkdir -p ${REPO_PATH}/${volume_name}
    
    # Initialize the Borg repository
    docker run --rm \
        -v ${REPO_PATH}/${volume_name}:/repo \
        -e BORG_PASSPHRASE=${BORG_PASSPHRASE} \
        -e BORG_REPO=/repo \
        mrt/borgbackup init --encryption=none /repo
}

# Function to create a backup from a volume
# Arguments:
#   1. Volume name
create_archive() {
    local volume_name=$1
    
    local timestamp=$(date +%Y-%m-%d_%H-%M-%S)
    local repository_path=${REPO_PATH}/${volume_name}

    # Create a backup of the volume
    echo "Creating backup of volume $volume_name..."
    docker run --rm \
        -v ${REPO_PATH}/${volume_name}:/repo \
        -v ${volume_name}:/data:ro \
        -e BORG_PASSPHRASE=${BORG_PASSPHRASE} \
        -e BORG_REPO=/repo \
        -e BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK=yes \
        mrt/borgbackup create \
            --verbose \
            --progress \
            --stats \
            --show-rc \
            --compression zlib \
            /repo::${volume_name}-${timestamp} /data
}

# Prune old backups
# Arguments:
#   1. Volume name
prune_backups() {
    local volume_name=$1
    local repository_path=${REPO_PATH}/${volume_name}

    echo "Pruning old backups for volume $volume_name..."
    docker run --rm \
        -v ${REPO_PATH}/${volume_name}:/repo \
        -e BORG_PASSPHRASE=${BORG_PASSPHRASE} \
        -e BORG_REPO=/repo \
        -e BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK=yes \
        mrt/borgbackup prune \
            --list \
            --show-rc \
            --keep-daily=7 \
            --keep-weekly=4 \
            --keep-monthly=6 \
            --keep-yearly=2
    
    # Compact the repository
    echo "Compacting repository for volume $volume_name..."
    docker run --rm \
        -v ${REPO_PATH}/${volume_name}:/repo \
        -e BORG_PASSPHRASE=${BORG_PASSPHRASE} \
        -e BORG_REPO=/repo \
        -e BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK=yes \
        mrt/borgbackup compact \
            /repo
}

# Pause docker-compose services
# Arguments:
#   1. Volume name
pause_compose() {
    local volume_name=$1

    # Check if the docker-compose services are already paused
    if docker compose -f ${SCRIPT_DIR}/../${volume_name}/docker-compose.yml ps | grep -q "Paused"; then
        echo "Docker-compose services for volume $volume_name are already paused."
        return
    fi

    echo "Pausing docker-compose services for volume $volume_name..."
    docker compose -f ${SCRIPT_DIR}/../${volume_name}/docker-compose.yml pause
}

# Unpause docker-compose services
# Arguments:
#   1. Volume name
unpause_compose() {
    local volume_name=$1

    # Check if the docker-compose services are already unpaused
    if ! docker compose -f ${SCRIPT_DIR}/../${volume_name}/docker-compose.yml ps | grep -q "Paused"; then
        echo "Docker-compose services for volume $volume_name are already unpaused."
        return
    fi

    echo "Unpausing docker-compose services for volume $volume_name..."
    docker compose -f ${SCRIPT_DIR}/../${volume_name}/docker-compose.yml unpause
}
              
# Create backup for volume
# Arguments:
#   1. Volume name
create_backup() {
    local volume_name=$1

    initialize_repo ${volume_name}
    create_archive  ${volume_name}
    prune_backups   ${volume_name}
}

#
# Nextcloud
#
pause_compose   nextcloud
create_backup   nextcloud
create_backup   nextcloud_db
unpause_compose nextcloud

#
# Jellyfin
#
pause_compose   jellyfin
create_backup   jellyfin
unpause_compose jellyfin

#
# Paperless
#
pause_compose paperless
create_backup paperless_db
create_backup perless_data
unpause_compose paperless

#
# Treafik
#
pause_compose   traefik
create_backup   traefik_certs
create_backup   traefik_config  
unpause_compose traefik

#
# Vaultwarden
#
pause_compose   vaultwarden
create_backup   vaultwarden_data
unpause_compose vaultwarden