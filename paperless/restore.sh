#!/bin/bash

DRY_RUN=""
# Check parameter 
if [ "$1" != "--execute" ]; then
    DRY_RUN=" --dry-run"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "!!!!    DRY RUN: No changes will be made.    !!!!"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
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
BORG_REPO_PAPERLESS_DATA="paperless_data"
BORG_REPO_PAPERLESS_DB="paperless_db"

RESTORE_BASE_DIR="${SCRIPT_DIR}/restore"
RESTORE_DATA="${RESTORE_BASE_DIR}/${BORG_REPO_PAPERLESS_DATA}"
RESTORE_DB="${RESTORE_BASE_DIR}/${BORG_REPO_PAPERLESS_DB}"

restore_from_borg() {
    local repo_name=$1
    local restore_dir=$2

    local latest_archive=$(get_latest_archive "${BORG_REPO_BASE}/${repo_name}")
    echo "Restoring from archive: ${latest_archive}"

    cd ${restore_dir}
    sudo borg extract --progress ${BORG_REPO_BASE}/${repo_name}::${latest_archive} ${DRY_RUN}
}

#
# Cleanup restore directory
#
sudo rm -Rf ${RESTORE_BASE_DIR}
mkdir -p ${RESTORE_DATA}
mkdir -p ${RESTORE_DB}

# Restore data from borg
restore_from_borg "${BORG_REPO_PAPERLESS_DATA}" "${RESTORE_DATA}"
# Restore db from borg
restore_from_borg "${BORG_REPO_PAPERLESS_DB}" "${RESTORE_DB}"

# Back to script directory
cd ${SCRIPT_DIR}
