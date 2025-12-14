#!/bin/bash

#
# Get parameters
#
DO_JELLYFIN=1
DO_NEXTCLOUD=1
DO_PAPERLESS=1
DO_TRAEFIK=1
DO_VAULTWARDEN=1
DO_AUDIOBOOKSHELF=1

# Only jellyfin
if [ "$1" == "--jellyfin" ]; then
    DO_JELLYFIN=1
    DO_NEXTCLOUD=0
    DO_PAPERLESS=0
    DO_TRAEFIK=0
    DO_VAULTWARDEN=0
    DO_AUDIOBOOKSHELF=0
# Only nextcloud
elif [ "$1" == "--nextcloud" ]; then
    DO_JELLYFIN=0
    DO_NEXTCLOUD=1
    DO_PAPERLESS=0
    DO_TRAEFIK=0
    DO_VAULTWARDEN=0
    DO_AUDIOBOOKSHELF=0
# Only paperless
elif [ "$1" == "--paperless" ]; then
    DO_JELLYFIN=0
    DO_NEXTCLOUD=0
    DO_PAPERLESS=1
    DO_TRAEFIK=0
    DO_VAULTWARDEN=0
    DO_AUDIOBOOKSHELF=0
# Only traefik
elif [ "$1" == "--traefik" ]; then
    DO_JELLYFIN=0
    DO_NEXTCLOUD=0
    DO_PAPERLESS=0
    DO_TRAEFIK=1
    DO_VAULTWARDEN=0
    DO_AUDIOBOOKSHELF=0
# Only vaultwarden
elif [ "$1" == "--vaultwarden" ]; then
    DO_JELLYFIN=0
    DO_NEXTCLOUD=0
    DO_PAPERLESS=0
    DO_TRAEFIK=0
    DO_VAULTWARDEN=1
    DO_AUDIOBOOKSHELF=0
# Only audiobookshelf
elif [ "$1" == "--audiobookshelf" ]; then
    DO_JELLYFIN=0
    DO_NEXTCLOUD=0
    DO_PAPERLESS=0
    DO_TRAEFIK=0
    DO_VAULTWARDEN=0
    DO_AUDIOBOOKSHELF=1
fi


# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Rository base path
REPO_PATH=/nfs_shares/backup/homer/borgbackup
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
#   2. Number of daily backups to keep
#   3. Number of weekly backups to keep
#   4. Number of monthly backups to keep
#   5. Number of yearly backups to keep
prune_backups() {
    local volume_name=$1
    local daily_backups=$2
    local weekly_backups=$3
    local monthly_backups=$4
    local yearly_backups=$5
    
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
            --keep-daily=${daily_backups} \
            --keep-weekly=${weekly_backups} \
            --keep-monthly=${monthly_backups} \
            --keep-yearly=${yearly_backups}
    
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
#   2. Number of daily backups to keep
#   3. Number of weekly backups to keep
#   4. Number of monthly backups to keep
#   5. Number of yearly backups to keep
create_backup() {
    local volume_name=$1
    local daily_backups=$2
    local weekly_backups=$3
    local monthly_backups=$4
    local yearly_backups=$5

    initialize_repo ${volume_name}
    create_archive  ${volume_name}
    prune_backups   ${volume_name} ${daily_backups} ${weekly_backups} ${monthly_backups} ${yearly_backups}
}

# #
# # Nextcloud
# #
# if [ $DO_NEXTCLOUD -eq 1 ]; then
#     pause_compose   nextcloud
#
#     create_backup   nextcloud      7 4 6 2
#     create_backup   nextcloud_db   7 4 6 2
#
#     unpause_compose nextcloud
# fi

# #
# # Jellyfin
# #
# if [ $DO_JELLYFIN -eq 1 ]; then
#     pause_compose   jellyfin
#
#     create_backup   jellyfin_data  3 0 0 0
#
#     unpause_compose jellyfin
# fi

# #
# # Paperless
# #
# if [ $DO_PAPERLESS -eq 1 ]; then
#     pause_compose paperless
#
#     create_backup paperless_db    7 4 6 2
#     create_backup paperless_data  7 4 6 2
#
#     unpause_compose paperless
# fi

# #
# # Treafik
# #
# if [ $DO_TRAEFIK -eq 1 ]; then
#     pause_compose   traefik
#
#     create_backup   traefik_certs    7 4 6 2
#     create_backup   traefik_config   7 4 6 2
#
#     unpause_compose traefik
# fi

# #
# # Vaultwarden
# #
# if [ $DO_VAULTWARDEN -eq 1 ]; then
#     pause_compose   vaultwarden
#
#     create_backup   vaultwarden_data   7 4 6 2
#
#     unpause_compose vaultwarden
# fi

# #
# # Audiobookshelf
# #
# if [ $DO_AUDIOBOOKSHELF -eq 1 ]; then
#     pause_compose   audiobookshelf
#
#     create_backup   audiobookshelf_config      3 1 1 0
#     create_backup   audiobookshelf_metadata    3 1 1 0
#
#     unpause_compose audiobookshelf
# fi
