#!/usr/bin/env bash
# Build a docker image with the given username, user id, group id, image name and ROS distro as given in the setup.env file

source setup.env

echo "Building image $IMAGE_NAME using USERNAME=$USERNAME USER_UID=$USER_UID USER_GID=$USER_GID"

docker build --build-arg="USER_UID=$USER_UID" \
    --build-arg="USER_GID=$USER_GID" \
    --build-arg="USERNAME=$USERNAME" \
    --build-arg="ROS_DISTRO=$ROS_DISTRO" \
    -t $IMAGE_NAME:latest .
