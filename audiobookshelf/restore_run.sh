#!/bin/bash

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

VOLUME_CONFIG=${SCRIPT_DIR}/restore/audiobookshelf_config/data \
VOLUME_METADATA=${SCRIPT_DIR}/restore/audiobookshelf_metadata/data \
docker compose up -d
