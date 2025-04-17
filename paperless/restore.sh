#!/bin/bash

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source ${SCRIPT_DIR}/../borgbackup/borg_helpers.sh
check_dry_run "$1"

#
# Settings
#
RESTORE_BASE_DIR="${SCRIPT_DIR}/restore"

# Restore repositories from borg
restore_from_borg "paperless_data"
restore_from_borg "paperless_db"
