#!/bin/sh

# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

stop_stack(){
    stack_path=$SCRIPT_DIR/$1/docker-compose.yml
    echo "Start $1"

    docker compose -f $stack_path down
}

stop_stack traefik
stop_stack nextcloud
stop_stack paperless
stop_stack jellyfin