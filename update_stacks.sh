#!/bin/sh

docker_cmd=/usr/bin/docker

# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Stack list
source ${SCRIPT_DIR}/stacks.sh

update_stack(){
    stack_path=$SCRIPT_DIR/$1/docker-compose.yml

    echo "Stop $1"
    ${docker_cmd} compose -f $stack_path down

    echo "Update $1"
    ${docker_cmd} compose -f $stack_path pull

    echo "Start $1"
    ${docker_cmd} compose -f $stack_path up -d
}

pull_stacks(){
    stacks=$1

    for service in "${stacks[@]}"
    do
        stack_path=$SCRIPT_DIR/$service/docker-compose.yml
        echo "### Pulling $service"

        ${docker_cmd} compose -f $stack_path pull
    done
}

stop_stacks(){
    stacks=$1

    for service in "${stacks[@]}"
    do
        stack_path=$SCRIPT_DIR/$service/docker-compose.yml
        echo "### Stopping $service"

        ${docker_cmd} compose -f $stack_path down
    done
}

start_stacks(){
    stacks=$1

    for service in "${stacks[@]}"
    do
        stack_path=$SCRIPT_DIR/$service/docker-compose.yml
        echo "### Stopping $service"

        ${docker_cmd} compose -f $stack_path up -d
    done
}

pull_stacks $stacks
stop_stacks $stacks
start_stacks $stacks

echo "Remove unused docker images"
${docker_cmd} image prune -f
