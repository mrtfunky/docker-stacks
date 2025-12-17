#!/bin/bash

BORG_REPO_BASE=/nfs_shares/backup/borgbackup

check_dry_run() {
    DRY_RUN=""
    # Check parameter 
    if [ "$1" != "--execute" ]; then
        DRY_RUN=" --dry-run"
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo "!!!!    DRY RUN: No changes will be made.    !!!!"
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    fi

    export DRY_RUN
}

get_latest_borg_archive() {
    local repo_path=$1
    borg list "${repo_path}" --short | sort | tail -n 1
}

restore_from_borg() {
    local repo_name=$1
    
    # Check if BORG_REPO_BASE is set
    if [ -z "${RESTORE_BASE_DIR}" ]; then
        echo "RESTORE_BASE_DIR is not set!"
        exit 1
    fi

    local repo_name_path="${BORG_REPO_BASE}/${repo_name}"
    local restore_dir="${RESTORE_BASE_DIR}/${repo_name}"
    local latest_archive=$(get_latest_borg_archive "${repo_name_path}")

    echo "Restoring from archive: ${latest_archive}"

    # Create/Cleanup old restore directory
    mkdir -p ${restore_dir}
    sudo rm -Rf ${restore_dir}/*

    # Store current directory
    local current_dir=$(pwd)
    cd ${restore_dir}

    # Restore the latest archive
    sudo borg extract --progress ${repo_name_path}::${latest_archive} ${DRY_RUN}

    # Return to the original directory
    cd ${current_dir}
}

# Mount remote backup location via NFS
#
# Mounts the remote NFS backup location to the local BACKUP_DESTINATION directory.
# No parameters.
mount_backup_location() {
    # if mount point does not exist, create it
    if [ ! -d "${BACKUP_DESTINATION}" ]; then
        mkdir -p "${BACKUP_DESTINATION}"
    fi
    
    # if not already mounted, mount it
    if mountpoint -q "${BACKUP_DESTINATION}"; then
        echo "Backup location already mounted."
        return
    fi

    echo "Mounting remote backup location..."
    mount -t nfs ${HOST}:${REPO_PATH} ${BACKUP_DESTINATION}
    if [ $? -ne 0 ]; then
        echo "Error: Failed to mount NFS backup location at ${BACKUP_DESTINATION}."
        exit 1
    fi
}

#
# Unmount remote backup location
#
# Unmounts the remote NFS backup location from the local BACKUP_DESTINATION directory.
# No parameters.
unmount_backup_location() {
    # Check if already unmounted
    if ! mountpoint -q "${BACKUP_DESTINATION}"; then
        echo "Backup location already unmounted."
        return
    fi
    
    echo "Unmounting remote backup location..."
    umount "${BACKUP_DESTINATION}"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to unmount ${BACKUP_DESTINATION}."
        exit 1
    fi

    # Cleanup mount point directory
    rmdir "${BACKUP_DESTINATION}"
}

#
# Create borg repository under mount point
# 
# Parameters:
#   $1 - Repository name
#
create_repository() {
    local folder_path=$1
    local repo_name=$(basename "${folder_path}")

    # Check if repository already exists
    if [ -f "${BACKUP_DESTINATION}/${repo_name}/README" ]; then
        echo "Borg repository for ${repo_name} already exists. Skipping creation."
        return
    fi

    echo "Creating borg repository for ${repo_name}..."
    borg init \
        --encryption=none \
        ${BACKUP_DESTINATION}/${repo_name}

    # Check if borg init was successful
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create borg repository for ${repo_name}."
        exit 1
    fi
}

#
# Backup a local folder to remote borg repository
# 
# Parameters:
#   $1 - Folder path
#
backup_folder() {
    local folder_path=$1
    local timestamp=$(date +%Y-%m-%d_%H-%M-%S)
    local repo_name=$(basename "${folder_path}")

    echo "Backing up folder ${folder_path}..."
    borg create \
        --verbose \
        --progress \
        --stats \
        --show-rc \
        --compression zlib \
        ${BACKUP_DESTINATION}/${repo_name}::${repo_name}-${timestamp} ${folder_path}

    # Check if borg create was successful
    if [ $? -ne 0 ]; then
        echo "Error: Failed to back up folder ${repo_name}."
        exit 1
    fi

    echo "Backup of folder ${repo_name} completed successfully."
}

#
# Prune old backups in remote borg repository
# 
# Parameters:
#   $1 - Folder path
#   $2 - Number of daily backups to keep
#   $3 - Number of weekly backups to keep
#   $4 - Number of monthly backups to keep
#   $5 - Number of yearly backups to keep
#
prune_backups() {
    local folder_path=$1
    local folder_name=$(basename "${folder_path}")
    local daily_backups=$2
    local weekly_backups=$3
    local monthly_backups=$4
    local yearly_backups=$5

    echo "Pruning old backups for folder ${folder_name}..."
    borg prune \
        --list \
        --show-rc \
        --keep-daily=$daily_backups \
        --keep-weekly=$weekly_backups \
        --keep-monthly=$monthly_backups \
        --keep-yearly=$yearly_backups \
        ${BACKUP_DESTINATION}/${folder_name}

    # Check if borg prune was successful
    if [ $? -ne 0 ]; then
        echo "Error: Failed to prune backups for folder ${folder_name}."
        exit 1
    fi
}

#
# Stop stacks before backup
#
stop_stacks() {
    echo "Stopping stacks before backup..."

    for stack in "${STASKS_TO_STOP[@]}"; do
        echo "Stopping stack: ${stack}"
        docker compose -f ${SCRIPT_DIR}/../${stack}/docker-compose.yml down
        if [ $? -ne 0 ]; then
            echo "Error: Failed to stop stack ${stack}."
            exit 1
        fi
    done
}

#
# Start stacks after backup
#
start_stacks() {
    echo "Starting stacks after backup..."

    for stack in "${STASKS_TO_STOP[@]}"; do
        echo "Starting stack: ${stack}"
        docker compose -f ${SCRIPT_DIR}/../${stack}/docker-compose.yml up -d
    done
}

# Funnction to list stats and folders backups on the remote backup location
# Parameters:
#   repo_name - Name of the repository to list backups for
list_backups() {
    local repo_name=$1

    echo ""
    echo "##################################################"
    echo "Repository: ${repo_name}"
    echo "##################################################"
    borg info ${BACKUP_DESTINATION}/${repo_name}
    borg list ${BACKUP_DESTINATION}/${repo_name}
}

# Function to check if a backup for a given repositiry was performed today
# Parameters:
#   repo_name - Name of the repository to check backup for
check_backup_today() {
    local repo_name=$1
    local latest_archive=$(get_latest_borg_archive "${BACKUP_DESTINATION}/${repo_name}")
    local today_date=$(date +%Y-%m-%d)

    if [[ $latest_archive == ${repo_name}-${today_date}* ]]; then
        echo "* GOOD * Backup for repository ${repo_name} was performed today (${today_date})."
        return 0
    else
        echo "!!! ALERT !!! No backup for repository ${repo_name} found for today (${today_date})."
        return 1
    fi
}