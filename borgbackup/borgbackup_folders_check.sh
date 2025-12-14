#!/bin/bash

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Local mount point for NFS
BACKUP_DESTINATION=${SCRIPT_DIR}/mnt_backup

# Import or define configuration and folder list
source ${SCRIPT_DIR}/borgbackup_config.sh
# Import helper functions
source ${SCRIPT_DIR}/borg_helpers.sh

# Funnction to list stats and folders backups on the remote backup location
# Parameters:
#   repo_name - Name of the repository to list backups for
list_backups() {
    local repo_name=$1

    echo "##################################################"
    echo "Repository: ${repo_name}"
    echo "##################################################"
    borg info ${BACKUP_DESTINATION}/${repo_name}
    borg list ${BACKUP_DESTINATION}/${repo_name}
}

# Main script execution
mount_backup_location "${BACKUP_DESTINATION}"

# List backups for each repository specified in FOLDERS_TO_BACKUP
for folder_entry in "${FOLDERS_TO_BACKUP[@]}"; do
    # Extract folder path and retention policies
    IFS=':' read -r folder_path daily weekly monthly yearly <<< "${folder_entry}"
    
    # Derive repository name from folder path
    repo_name=$(basename "${folder_path}")
    
    list_backups "${repo_name}"
done

unmount_backup_location "${BACKUP_DESTINATION}"