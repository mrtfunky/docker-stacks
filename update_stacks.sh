#!/bin/sh

docker_cmd=/usr/bin/docker

# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


# Read parameters
# --pull: pull only
# --stop: stop only
# --start: start only
# --restart: stop and start
# --all: pull, stop and start
do_pull=true
do_stop=true
do_start=true

if [ $# -eq 0 ]; then
    do_pull=true
    do_stop=true
    do_start=true
elif [ $# -gt 1 ]; then
    echo "Usage: $0 [--pull | --stop | --start | --restart | --all]"
    exit 1
elif [ "$1" = "--pull" ]; then
    do_pull=true
    do_stop=false
    do_start=false
elif [ "$1" = "--stop" ]; then
    do_pull=false
    do_stop=true
    do_start=false
elif [ "$1" = "--start" ]; then
    do_pull=false
    do_stop=false
    do_start=true
elif [ "$1" = "--restart" ]; then
    do_pull=false
    do_stop=true
    do_start=true
elif [ "$1" = "--all" ]; then
    do_pull=true
    do_stop=true
    do_start=true
else
    echo "Unknown option: $1"
    exit 1
fi


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

    # Array of pids
    pids=()

    # Loop through the stacks and stop them
    for service in "${stacks[@]}"
    do
        stack_path=$SCRIPT_DIR/$service/docker-compose.yml
        echo "### Stopping $service ..."

        # Stop the stack in the background and save the pid in the array
        ${docker_cmd} compose -f $stack_path down &
        pid=$!
        pids+=($pid)
    done

    # Wait for all background processes to finish
    for pid in ${pids[@]}; do
        wait $pid
    done    
    echo "### All stacks stopped."
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

if [ "$do_pull" = true ]; then
    echo "Pulling stacks"
    pull_stacks $stacks
fi

if [ "$do_stop" = true ]; then
    echo "Stopping stacks"
    stop_stacks $stacks
fi

if [ "$do_start" = true ]; then
    echo "Starting stacks"
    start_stacks $stacks

    echo "Removing unused docker images"
    ${docker_cmd} image prune -f
fi
