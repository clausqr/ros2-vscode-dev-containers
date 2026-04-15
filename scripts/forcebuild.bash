#!/usr/bin/env bash
# Force build (--no-cache) a docker image with the given username, user id, group id, image name and ROS distro as given in the setup.env file

source setup.env

echo "Building image $RR_IMAGE_NAME using RR_USERNAME=$RR_USERNAME RR_USER_UID=$RR_USER_UID RR_USER_GID=$RR_USER_GID"
echo "Using RR_ROS_DISTRO=$RR_ROS_DISTRO"
if [ "$RR_SSH_ENABLED" = "1" ]; then
    echo "SSH enabled on port RR_SSH_PORT=$RR_SSH_PORT"
fi

docker build --no-cache \
    --build-arg="RR_USER_UID=$RR_USER_UID" \
    --build-arg="RR_USER_GID=$RR_USER_GID" \
    --build-arg="RR_USERNAME=$RR_USERNAME" \
    --build-arg="RR_ROS_DISTRO=$RR_ROS_DISTRO" \
    --build-arg="RR_SSH_PORT=$RR_SSH_PORT" \
    -t $RR_IMAGE_NAME:latest .
