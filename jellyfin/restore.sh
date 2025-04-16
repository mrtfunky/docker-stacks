#!/bin/bash

DRY_RUN=""
# Check parameter 
if [ "$1" != "--execute" ]; then
    DRY_RUN=" --dry-run"
fi

get_latest_archive() {
    borg list "$1" --short | sort | tail -n 1
}

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

#
# Settings
#
BORG_REPO_BASE=/nfs_shares/backup/borgbackup
BORG_REPO_JELLYFIN="jellyfin_data"

RESTORE_BASE_DIR="${SCRIPT_DIR}/restore"
RESTORE_NC_JELLYFIN="${RESTORE_BASE_DIR}/${BORG_REPO_JELLYFIN}"

#
# Cleanup restore directory
#
sudo rm -Rf ${RESTORE_BASE_DIR}
mkdir -p ${RESTORE_NC_JELLYFIN}

#
# Restore Jellyfin from borg
#
LATEST_ARCHIVE=$(get_latest_archive "${BORG_REPO_BASE}/${BORG_REPO_JELLYFIN}")
echo "Restoring Jellyfin from archive: ${LATEST_ARCHIVE}"

cd ${RESTORE_NC_JELLYFIN}
sudo borg extract --progress ${BORG_REPO_BASE}/${BORG_REPO_JELLYFIN}::${LATEST_ARCHIVE} ${DRY_RUN}

# Back to script directory
cd ${SCRIPT_DIR}
