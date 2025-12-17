#!/bin/bash

# Check if script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Please use sudo."
    exit 1
fi

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Mount point for NFS in the temp directory
BACKUP_DESTINATION="/tmp/borgbackup_nfs_mount"

# Parse parameters
#   --stacks : Backup only docker stacks
#   --folders: Backup only non-docker-stack folders
#   --all    : Backup all folders
#   --status : Check backup status
BACKUP_STACKS=1
BACKUP_FOLDERS=1
BACKUP_STATUS=0
BACKUP_TODAY=0
for arg in "$@"; do
    case $arg in
        --stacks)
            BACKUP_STACKS=1
            BACKUP_FOLDERS=0
            ;;
        --folders)
            BACKUP_STACKS=0
            BACKUP_FOLDERS=1
            ;;
        --all)
            BACKUP_STACKS=1
            BACKUP_FOLDERS=1
            ;;
        --status)
            BACKUP_STACKS=0
            BACKUP_FOLDERS=0
            BACKUP_STATUS=1
            ;;
        --today)
            BACKUP_STACKS=0
            BACKUP_FOLDERS=0
            BACKUP_STATUS=0
            BACKUP_TODAY=1
            ;;
        *)
            echo "Unknown parameter: $arg"
            exit 1
            ;;
    esac
done


# Import or define configuration and folder list
# Needs to define:
#   HOST - NFS host
#   REPO_PATH - NFS export path
#   FOLDERS_TO_BACKUP - Array of folders to back up with retention policies (e.g. "/path/to/folder:7:3:6:1")
#   STASKS_TO_STOP - Array of stack names to stop before backup (e.g. "jellyfin", "paperless")
source ${SCRIPT_DIR}/borgbackup_config.sh

# Import helper functions
source ${SCRIPT_DIR}/borg_helpers.sh

# Mount NFS backup location
mount_backup_location "${BACKUP_DESTINATION}"

#
# Backup stacks
#
if [ $BACKUP_STACKS -eq 1 ]; then
    echo ""
    echo "### Backing up docker stacks ###"
    echo ""

    stop_stacks

    for folder in "${FOLDERS_TO_BACKUP[@]}"; do
        IFS=':' read -r folder_path daily weekly monthly yearly <<< "${folder}"

        create_repository "${folder_path}"
        backup_folder     "${folder_path}"
        prune_backups     "${folder_path}" ${daily} ${weekly} ${monthly} ${yearly}
    done

    start_stacks
fi

#
# Backup non docker folders
#
if [ $BACKUP_FOLDERS -eq 1 ]; then
    echo ""
    echo "### Backing up extra folders ###"
    echo ""

     for folder in "${EXTRA_FOLDERS_TO_BACKUP[@]}"; do
        IFS=':' read -r folder_path daily weekly monthly yearly <<< "${folder}"

        create_repository "${folder_path}"
        backup_folder     "${folder_path}"
        prune_backups     "${folder_path}" ${daily} ${weekly} ${monthly} ${yearly}
    done
fi

#
# Check backup status
#
if [ $BACKUP_STATUS -eq 1 ]; then
    echo ""
    echo "### Checking backup status ###"
    echo ""

    # List backups for each repository specified in FOLDERS_TO_BACKUP
    for folder_entry in "${FOLDERS_TO_BACKUP[@]}"; do
        # Extract folder path and retention policies
        IFS=':' read -r folder_path daily weekly monthly yearly <<< "${folder_entry}"
        
        # Derive repository name from folder path
        repo_name=$(basename "${folder_path}")      
        list_backups "${repo_name}"
    done

    # List backups for each repository specified in EXTRA_FOLDERS_TO_BACKUP
    for folder_entry in "${EXTRA_FOLDERS_TO_BACKUP[@]}"; do
        # Extract folder path and retention policies
        IFS=':' read -r folder_path daily weekly monthly yearly <<< "${folder_entry}"

        # Derive repository name from folder path
        repo_name=$(basename "${folder_path}")
        list_backups "${repo_name}"
    done
fi

#
# Check today's backup status
#
if [ $BACKUP_TODAY -eq 1 ]; then
    echo ""
    echo "### Checking today's backup status ###"
    echo ""

    # Check today's backup for each repository specified in FOLDERS_TO_BACKUP
    for folder_entry in "${FOLDERS_TO_BACKUP[@]}"; do
        # Extract folder path and retention policies
        IFS=':' read -r folder_path daily weekly monthly yearly <<< "${folder_entry}"
        
        # Derive repository name from folder path
        repo_name=$(basename "${folder_path}")      
        check_backup_today "${repo_name}"
    done

    # Check today's backup for each repository specified in EXTRA_FOLDERS_TO_BACKUP
    for folder_entry in "${EXTRA_FOLDERS_TO_BACKUP[@]}"; do
        # Extract folder path and retention policies
        IFS=':' read -r folder_path daily weekly monthly yearly <<< "${folder_entry}"

        # Derive repository name from folder path
        repo_name=$(basename "${folder_path}")
        check_backup_today "${repo_name}"
    done
fi

# Unmount NFS backup location
unmount_backup_location "${BACKUP_DESTINATION}" 

# Check if script executed successfully
if [ $? -eq 0 ]; then
    echo "All folder backups completed successfully."
else
    echo "Error: Some folder backups failed."
    exit 1
fi
