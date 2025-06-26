#!/usr/bin/env bash
# Join a running container with the given name using the username, user id, and group id as given in the setup.env file

source setup.env

# Default value
default_container_name=$IMAGE_NAME

# Parse command line arguments, add your own arguments here
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --name)
            container_name="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [--name <container_name>]"
            exit 0
            ;;
        *)
            echo "Unknown parameter passed: $1"
            exit 1
            ;;
    esac
done

# Use the default value if no --name argument was passed
container_name="${container_name:-$default_container_name}"

# Wait until the container is up
while [[ $(docker inspect -f '{{.State.Running}}' $container_name) != "true" ]]; do
    echo "Waiting for container $container_name to be up..."
    sleep 1
done

echo "Joining running container $container_name using USERNAME=$USERNAME USER_UID=$USER_UID USER_GID=$USER_GID"

docker exec -it $container_name bash --login -c "[ -f /ros2_ws/install/setup.bash ] && source /ros2_ws/install/setup.bash; exec bash"