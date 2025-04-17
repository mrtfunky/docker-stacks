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
