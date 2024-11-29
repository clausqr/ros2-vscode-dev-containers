#!/usr/bin/env bash
# Force build (--no-cache) a docker image with the given username, user id, group id, image name and ROS distro as given in the setup.env file

source setup.env

echo "Building image $IMAGE_NAME using USERNAME=$USERNAME USER_UID=$USER_UID USER_GID=$USER_GID"
echo "Using ROS_DISTRO=$ROS_DISTRO"
if [ "$SSH_ENABLED" = "true" ]; then
    echo "SSH enabled on port SSH_PORT=$SSH_PORT"
fi

docker build --no-cache \
    --build-arg="USER_UID=$USER_UID" \
    --build-arg="USER_GID=$USER_GID" \
    --build-arg="USERNAME=$USERNAME" \
    --build-arg="ROS_DISTRO=$ROS_DISTRO" \
    --build-arg="SSH_ENABLED=$SSH_ENABLED" \
    --build-arg="SSH_PORT=$SSH_PORT" \
    -t $IMAGE_NAME:latest .
