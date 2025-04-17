#!/bin/bash

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

VOLUME_DATA=${SCRIPT_DIR}/restore/vaultwarden_data/data \
docker compose up -d


