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
# --help                   Display usage information and exit.

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

echo "Running image $IMAGE_NAME using USERNAME=$USERNAME USER_UID=$USER_UID USER_GID=$USER_GID"
echo "Container will be named $container_name"
echo

flags=""

# Check for serial port availability
for n in {0..9}; do
    if [ -e "/dev/ttyUSB$n" ]; then
        echo "/dev/ttyUSB$n is available"
        flags+=" --device=/dev/ttyUSB$n"
        break
    else
        echo "/dev/ttyUSB$n is not available"
    fi
done
for n in {0..9}; do
    if [ -e "/dev/ttyACM$n" ]; then
        echo "/dev/ttyACM$n is available"
        flags+=" --device=/dev/ttyACM$n:/dev/ttyACM0 --group-add dialout"
        break
    else
        echo "/dev/ttyACM$n is not available"
    fi
done
echo "Collected flags: ${flags}"

# Check for display availability
if [ -z "$DISPLAY" ]; then
    echo "No display available"
else
    flags+=" -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix -v /dev/dri:/dev/dri -v /dev/shm:/dev/shm"
    echo "Display available"
fi
echo "Collected flags: ${flags}"

# Check for NVIDIA GPU availability
if which nvidia-smi &>/dev/null; then
    echo "NVIDIA GPU available"
    flags+=" --gpus=all"
else
    echo "No NVIDIA GPU available"
fi

echo "Collected flags: ${flags}"

docker run -it \
    $flags \
    --rm \
    --net=host \
    --user $USER_UID:$USER_GID \
    -v $(pwd)/ros2_ws:/ros2_ws \
    --name $container_name \
    $IMAGE_NAME
