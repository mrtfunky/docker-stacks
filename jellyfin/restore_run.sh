#!/bin/bash

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

JELLYFIN_DATA=${SCRIPT_DIR}/restore/jellyfin_data/data \
docker compose up -d


