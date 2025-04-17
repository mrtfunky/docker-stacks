#!/bin/bash

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PAPERLESS_DATA=${SCRIPT_DIR}/restore/paperless_data/data \
PAPERLESS_DB=${SCRIPT_DIR}/restore/paperless_db/data \
docker compose up -d
