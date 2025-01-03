#!/bin/sh

docker_cmd=/usr/bin/docker

# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

start_stack(){
    stack_path=$SCRIPT_DIR/$1/docker-compose.yml
    echo "Start $1"

    ${docker_cmd} compose -f $stack_path up -d
}

# Stack list
source ${SCRIPT_DIR}/stacks.sh

# Start all stacks from list
for stack in ${stacks[@]}; do
    start_stack ${stack}
done
