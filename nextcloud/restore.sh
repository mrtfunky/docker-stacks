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
BORG_REPO_NC="nextcloud"
BORG_REPO_DB="nextcloud_db"

RESTORE_BASE_DIR="${SCRIPT_DIR}/restore"
RESTORE_NC_DIR="${RESTORE_BASE_DIR}/${BORG_REPO_NC}"
RESTORE_DB_DIR="${RESTORE_BASE_DIR}/${BORG_REPO_DB}"

#
# Cleanup restore directory
#
sudo rm -Rf ${RESTORE_BASE_DIR}
mkdir -p ${RESTORE_NC_DIR}
mkdir -p ${RESTORE_DB_DIR}

#
# Restore Nextcloud from borg
#
LATEST_ARCHIVE=$(get_latest_archive "${BORG_REPO_BASE}/${BORG_REPO_NC}")
echo "Restoring Nextcloud from archive: ${LATEST_ARCHIVE}"

cd ${RESTORE_NC_DIR}
sudo borg extract --progress ${BORG_REPO_BASE}/${BORG_REPO_NC}::${LATEST_ARCHIVE} ${DRY_RUN}

#
# Restore Nextcloud database from borg
#
LATEST_ARCHIVE=$(get_latest_archive "${BORG_REPO_BASE}/${BORG_REPO_DB}")
echo "Restoring Nextcloud database from archive: ${LATEST_ARCHIVE}"
cd ${RESTORE_DB_DIR}
sudo borg extract --progress ${BORG_REPO_BASE}/${BORG_REPO_DB}::${LATEST_ARCHIVE} ${DRY_RUN}

# Back to script directory
cd ${SCRIPT_DIR}
