#!/bin/sh

# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

start_stack(){
    stack_path=$SCRIPT_DIR/$1/docker-compose.yml
    echo "Start $1"

    docker compose -f $stack_path up -d
}

start_stack traefik
start_stack nextcloud
start_stack paperless
start_stack jellyfin
