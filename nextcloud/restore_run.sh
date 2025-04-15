#!/bin/bash

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

NEXTCLOUD_VOLUME=${SCRIPT_DIR}/restore/nextcloud/data \
NEXTCLOUD_VOLUME_DB=${SCRIPT_DIR}/restore/nextcloud_db/data \
docker compose up -d


