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
default_container_name=$RR_IMAGE_NAME

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
        flags+=" --device=$2"
        shift 2
        ;;
    *)
        echo "Unknown parameter passed: $1"
        exit 1
        ;;
    esac
done

# Use the default value if no --name argument was passed
container_name="${container_name:-$default_container_name}"

echo "Running image $RR_IMAGE_NAME using RR_USERNAME=$RR_USERNAME RR_USER_UID=$RR_USER_UID RR_USER_GID=$RR_USER_GID"
echo "Container will be named $container_name"
echo

# Check for display availability
if [ -z "$DISPLAY" ]; then
    echo "No display available"
else
    flags+=" -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix -v /dev/dri:/dev/dri -v /dev/shm:/dev/shm"
    echo "Display available"

    # Pass the X11 auth cookie into the container. On Wayland+Xwayland the
    # cookie lives in $XAUTHORITY (e.g. /run/user/1000/.mutter-Xwaylandauth.*),
    # not in ~/.Xauthority, so we mount whichever file actually has it. Without
    # this, GUI apps inside the container fail with "Authorization required".
    host_xauth=""
    if [ -n "$XAUTHORITY" ] && [ -f "$XAUTHORITY" ]; then
        host_xauth="$XAUTHORITY"
    elif [ -f "$HOME/.Xauthority" ]; then
        host_xauth="$HOME/.Xauthority"
    fi
    if [ -n "$host_xauth" ]; then
        flags+=" -v $host_xauth:/tmp/.docker.xauth:ro -e XAUTHORITY=/tmp/.docker.xauth"
        echo "Mounting X auth cookie from $host_xauth"
    else
        echo "Warning: no X authority file found; GUI apps may fail to connect to display"
    fi
fi
echo "Collected flags: ${flags}"

# Check for joystick availability
if [ -e /dev/input/js0 ]; then
    flags+=" --device=/dev/input/js0"
    echo "Joystick available"
else
    echo "No joystick available"
fi

# NVIDIA GPU passthrough is opt-in. Adding --gpus=all unconditionally breaks on
# hosts that have the driver but not nvidia-container-toolkit installed, so we
# only enable it when explicitly requested in setup.env.
if [ "${RR_GPU_ENABLED:-0}" -eq 1 ]; then
    if which nvidia-smi &>/dev/null; then
        echo "NVIDIA GPU available and enabled"
        flags+=" --gpus=all"
    else
        echo "RR_GPU_ENABLED=1 but nvidia-smi not found; skipping --gpus=all"
    fi
else
    echo "GPU disabled (RR_GPU_ENABLED=0)"
fi

echo "Collected flags: ${flags}"

# Conditionally add the mount for the SSH folder
ssh_mount=""
if [ "$RR_SSH_ENABLED" -eq 1 ]; then
    echo "SSH access is enabled for this container."
    echo "Mounting ~/.ssh folder (readonly), connect with the same credentials as the host."
    ssh_mount="--mount type=bind,source=${HOME}/.ssh,destination=/home/${RR_USERNAME}/.ssh,readonly"
    echo "Connect to the container with:"
    echo "  ssh -p ${RR_SSH_PORT} ${RR_USERNAME}@$(hostname -I | cut -d ' ' -f 1)"
else
    echo "SSH access is not enabled for this container."
fi

# Parse RR_VOLUMES (comma-separated host:container[:opts] entries) into mount
# flags. Lets downstream projects add extra bind-mounts via setup.env without
# patching this script.
additional_volume_flags=""
if [ -n "${RR_VOLUMES:-}" ]; then
    IFS=',' read -ra _rr_volumes <<< "$RR_VOLUMES"
    for volume in "${_rr_volumes[@]}"; do
        if [ -n "$volume" ]; then
            additional_volume_flags+=" -v $volume"
        fi
    done
fi

# Build the container startup command. SSH capability is always baked into the
# image; we start the service here only when RR_SSH_ENABLED=1, so toggling SSH
# no longer requires a rebuild. If the workspace contains an executable
# /ros2_ws/on_run.sh, source it after starting SSH so downstream projects can
# customise startup without editing this script.
hook_cmd=""
if [ -f "$(pwd)/ros2_ws/on_run.sh" ]; then
    hook_cmd="source /ros2_ws/on_run.sh && "
    echo "Will source /ros2_ws/on_run.sh on container start"
fi
if [ "$RR_SSH_ENABLED" -eq 1 ]; then
    startup_cmd="sudo service ssh start && echo 'SSH access enabled, connect with:' && echo \"ssh -l \$(whoami) -p \${RR_SSH_PORT} \$(hostname -I | cut -d ' ' -f 1)\" && ${hook_cmd}exec bash"
else
    startup_cmd="${hook_cmd}exec bash"
fi

docker run -it \
    $flags \
    --rm \
    --net=host \
    --user $RR_USER_UID:$RR_USER_GID \
    -e RR_SSH_ENABLED=$RR_SSH_ENABLED \
    -e RR_SSH_PORT=$RR_SSH_PORT \
    -v $(pwd)/ros2_ws:/ros2_ws \
    $additional_volume_flags \
    $ssh_mount \
    --name $container_name \
    $RR_IMAGE_NAME \
    bash -c "$startup_cmd"
