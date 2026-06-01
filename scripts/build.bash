#!/usr/bin/env bash
# Build a docker image with the given username, user id, group id, image name and ROS distro as given in the setup.env file

source setup.env

echo "Building image $RR_IMAGE_NAME using RR_USERNAME=$RR_USERNAME RR_USER_UID=$RR_USER_UID RR_USER_GID=$RR_USER_GID"
echo "Using RR_ROS_DISTRO=$RR_ROS_DISTRO"
if [ "$RR_SSH_ENABLED" = "1" ]; then
    echo "SSH enabled on port RR_SSH_PORT=$RR_SSH_PORT"
fi

# Make sure any submodules under ros2_ws/src are checked out before the build
# bind-mounts ros2_ws into the container. No-op if there are no submodules.
if [ -f .gitmodules ]; then
    echo "Initialising git submodules..."
    git submodule update --init --recursive
fi

# Pre-flight: verify host can reach Ubuntu/ROS package mirrors. If host DNS
# fails, the in-container apt-get update will also fail with "Temporary
# failure resolving 'archive.ubuntu.com'", so warn early with a useful hint.
echo "Pre-flight: checking DNS resolution for package mirrors..."
DNS_OK=1
for host in archive.ubuntu.com security.ubuntu.com packages.ros.org; do
    if ! getent hosts "$host" >/dev/null 2>&1; then
        echo "  ! Cannot resolve $host"
        DNS_OK=0
    fi
done

# Use host networking so the build inherits the host's DNS resolver.
# BuildKit/buildx does not accept --dns; --network=host is the supported
# escape hatch when the Docker daemon doesn't have DNS configured in
# /etc/docker/daemon.json.
NET_ARGS=(--network=host)
echo "Using --network=host for build (inherits host DNS)"

if [ "$DNS_OK" -eq 0 ]; then
    echo "WARNING: host DNS lookup failed for one or more package mirrors."
    echo "  Build will likely fail at apt-get update. Possible fixes:"
    echo "    - Check VPN/proxy is connected"
    echo "    - Add DNS to /etc/docker/daemon.json: { \"dns\": [\"8.8.8.8\", \"1.1.1.1\"] } && sudo systemctl restart docker"
    echo "    - Re-run after restoring connectivity"
fi

docker build "${NET_ARGS[@]}" \
    --build-arg="RR_USER_UID=$RR_USER_UID" \
    --build-arg="RR_USER_GID=$RR_USER_GID" \
    --build-arg="RR_USERNAME=$RR_USERNAME" \
    --build-arg="RR_ROS_DISTRO=$RR_ROS_DISTRO" \
    --build-arg="RR_SSH_PORT=$RR_SSH_PORT" \
    -t $RR_IMAGE_NAME:latest .

build_status=$?

# If the workspace ships a post_build.sh, run it inside a throwaway container
# with ros2_ws bind-mounted. Lets downstream projects do an initial colcon
# build, rosdep install, etc. without editing this script.
if [ $build_status -eq 0 ] && [ -f "$(pwd)/ros2_ws/post_build.sh" ]; then
    echo "Build successful, running ros2_ws/post_build.sh..."
    docker run --rm \
        --user $RR_USER_UID:$RR_USER_GID \
        -v $(pwd)/ros2_ws:/ros2_ws \
        ${RR_IMAGE_NAME}:latest \
        /bin/bash -c "source /opt/ros/${RR_ROS_DISTRO}/setup.bash && bash /ros2_ws/post_build.sh"
fi

exit $build_status
