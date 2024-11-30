#!/usr/bin/env bash
#
# DESCRIPTION:
# This script runs a Docker container with specific configurations defined in
# the setup.env file. It checks for necessary arguments and allows optional
# customization of the container name.
#
# USAGE:
# To run the script, execute:
#     rr run [--name <container_name>]
#
# OPTIONS:
# --name <container_name>  Specify a custom name for the Docker container. If not
#                          provided, a default name from the setup.env file is used.
# --device <device>        Specify a device to be passed to the Docker container.
# --help                   Display usage information and exit.
#
# EXAMPLES:
#
#   Run with mapped device ttyUSB17 on the host to ttyUSB0 in the container:
#    ./rr run --device /dev/ttyUSB17:/dev/ttyUSB0
#   Run with custom container name:
#    ./rr run --name my_container

source setup.env

# Default value
default_container_name=$IMAGE_NAME

# Flags to pass to the docker run command, to be populated based on the environment
flags=""

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
    --device)
        shift
        while [[ "$#" -gt 0 ]]; do
            device="$1"
            flags+=" --device=$device"
            shift
        done
        echo "Collected flags: ${flags}"
        ;;
    *)
        echo "Unknown parameter passed: $1"
        exit 1
        ;;
    esac
done

# Use the default value if no --name argument was passed
container_name="${container_name:-$default_container_name}"

echo "Running image $IMAGE_NAME using USERNAME=$USERNAME USER_UID=$USER_UID USER_GID=$USER_GID"
echo "Container will be named $container_name"
echo

# Check for display availability
if [ -z "$DISPLAY" ]; then
    echo "No display available"
else
    flags+=" -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix -v /dev/dri:/dev/dri -v /dev/shm:/dev/shm"
    echo "Display available"
fi
echo "Collected flags: ${flags}"

# Check for joystick availability
if [ -e /dev/input/js0 ]; then
    flags+=" --device=/dev/input/js0"
    echo "Joystick available"
else
    echo "No joystick available"
fi

# Check for NVIDIA GPU availability
if which nvidia-smi &>/dev/null; then
    echo "NVIDIA GPU available"
    flags+=" --gpus=all"
else
    echo "No NVIDIA GPU available"
fi

echo "Collected flags: ${flags}"

# Conditionally add the mount for the SSH folder
ssh_mount=""
if [ "$SSH_ENABLED" -eq 1 ]; then
    echo "SSH access is enabled for this container."
    echo "Mounting ~/.ssh folder, connect with the same credentials as the host."
    ssh_mount="--mount type=bind,source=${HOME}/.ssh,destination=/home/${USERNAME}/.ssh,readonly"
else
    echo "SSH access is not enabled for this container."
fi

docker run -it \
    $flags \
    --rm \
    --net=host \
    --user $USER_UID:$USER_GID \
    -v $(pwd)/ros2_ws:/ros2_ws \
    $ssh_mount \
    --name $container_name \
    $IMAGE_NAME
