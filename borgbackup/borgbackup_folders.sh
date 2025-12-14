#!/bin/bash

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Local mount point for NFS
BACKUP_DESTINATION=${SCRIPT_DIR}/mnt_backup

# Import or define configuration and folder list
# Needs to define:
#   HOST - NFS host
#   REPO_PATH - NFS export path
#   FOLDERS_TO_BACKUP - Array of folders to back up with retention policies (e.g. "/path/to/folder:7:3:6:1")
#   STASKS_TO_STOP - Array of stack names to stop before backup (e.g. "jellyfin", "paperless")
source ${SCRIPT_DIR}/borgbackup_config.sh

# Import helper functions
source ${SCRIPT_DIR}/borg_helpers.sh

#
# Create bor repository under mount point
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


###############################################################
# Main script execution
###############################################################

stop_stacks

mount_backup_location "${BACKUP_DESTINATION}"

for folder in "${FOLDERS_TO_BACKUP[@]}"; do
    IFS=':' read -r folder_path daily weekly monthly yearly <<< "${folder}"

    create_repository "${folder_path}"
    backup_folder     "${folder_path}"
    prune_backups     "${folder_path}" ${daily} ${weekly} ${monthly} ${yearly}
done

unmount_backup_location "${BACKUP_DESTINATION}"

start_stacks

###############################################################
# Main script execution end
###############################################################

# Check if script executed successfully
if [ $? -eq 0 ]; then
    echo "All folder backups completed successfully."
else
    echo "Error: Some folder backups failed."
    exit 1
fi
