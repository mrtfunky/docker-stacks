#!/bin/sh

docker_cmd=/usr/bin/docker

# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

stop_stack(){
    stack_path=$SCRIPT_DIR/$1/docker-compose.yml
    echo "Stop $1"

    ${docker_cmd} compose -f $stack_path down
}

source ${SCRIPT_DIR}/stacks.sh

for stack in ${stacks[@]}; do
    stop_stack ${stack}
done
