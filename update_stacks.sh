#!/bin/sh

# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

update_stack(){
    stack_path=$SCRIPT_DIR/$1/docker-compose.yml

    echo "Stop $1"
    docker compose -f $stack_path down

    echo "Update $1"
    docker compose -f $stack_path pull

    echo "Start $1"
    docker compose -f $stack_path up -d
}

update_stack traefik
update_stack nextcloud
update_stack paperless
update_stack jellyfin

echo "Remove uused docker images"
docker image prune -f
