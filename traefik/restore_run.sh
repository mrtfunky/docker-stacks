#!/bin/bash

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

VOLUME_CERTS=${SCRIPT_DIR}/restore/traefik_certs/data \
VOLUME_CONFIG=${SCRIPT_DIR}/restore/traefik_config/data \
docker compose up -d


