ARG RR_ROS_DISTRO=none
FROM osrf/ros:${RR_ROS_DISTRO}-desktop AS base
ARG RR_ROS_DISTRO=none
ARG RR_USERNAME=RR_USERNAME
ARG RR_USER_UID=RR_USER_UID
ARG RR_USER_GID=RR_USER_GID
ARG RR_IMAGE_NAME=RR_IMAGE_NAME

RUN echo "Building..."
RUN echo "+ RR_USERNAME=${RR_USERNAME}"
RUN echo "+ RR_USER_UID=${RR_USER_UID}"
RUN echo "+ RR_USER_GID=${RR_USER_GID}"


# # # # # # # # # # # # # # # # # # # #
# Create the user with same GID and UID as the host.
#
# Under ROOTLESS Docker the host user maps to container UID 0, so a rootless
# project sets RR_USER_UID/RR_USER_GID=0 (RR_USERNAME=root) for a writable
# bind-mounted workspace. In that case the account already exists (root), so we
# skip the create/delete dance and only wire up plugdev + passwordless sudo.
# Also add the user to plugdev so it can open USB device nodes when
# RR_USB_ENABLED=1 (run.bash injects the host plugdev GID at runtime).
# # # # # # # # # # #  # # # # # # # #
RUN if [ "${RR_USER_UID}" != "0" ]; then \
        if getent group ${RR_USER_GID}; then \
            for u in $(getent passwd | awk -F: -v gid=${RR_USER_GID} '$4 == gid {print $1}'); do usermod -g users "$u"; done; \
        fi; \
        if getent passwd ${RR_USER_UID}; then userdel -r "$(getent passwd ${RR_USER_UID} | cut -d: -f1)"; fi; \
        if getent group ${RR_USER_GID}; then groupdel "$(getent group ${RR_USER_GID} | cut -d: -f1)"; fi; \
        groupadd -g ${RR_USER_GID} ${RR_USERNAME}; \
        useradd -m -u ${RR_USER_UID} -g ${RR_USER_GID} -s /bin/bash ${RR_USERNAME}; \
    fi \
    && usermod -aG sudo ${RR_USERNAME} \
    && usermod -aG plugdev ${RR_USERNAME} \
    && echo "${RR_USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
# # # # # # # # # # # # # # # # # # # # #

ENV DEBIAN_FRONTEND=noninteractive

# Retry wrapper for transient DNS / mirror failures during build.
# Usage: apt_retry <apt-get args...>
RUN printf '#!/bin/sh\nset -e\nfor i in 1 2 3 4 5; do\n  if "$@"; then exit 0; fi\n  echo "apt step failed (attempt $i), retrying in 5s..." >&2\n  sleep 5\ndone\nexit 1\n' > /usr/local/bin/apt_retry && chmod +x /usr/local/bin/apt_retry

# Upgrade the base image (one-shot). Done on its own layer so theme layers
# below can be rebuilt independently.
RUN apt_retry apt-get update \
    && apt_retry apt-get upgrade -y \
    && rm -rf /var/lib/apt/lists/*

# Networking / SSH utilities used by the runtime scripts.
RUN apt_retry apt-get update \
    && apt_retry apt-get install -y --no-install-recommends \
        inetutils-tools \
        net-tools \
        ssh \
    && rm -rf /var/lib/apt/lists/*

# Developer shell ergonomics. Kept separate from the networking and ROS
# layers so adding a tool here doesn't rebuild the big ones.
RUN apt_retry apt-get update \
    && apt_retry apt-get install -y --no-install-recommends \
        tmux \
    && rm -rf /var/lib/apt/lists/*

# Python tooling. universe is required for python3-pip on Ubuntu Jammy.
RUN apt_retry apt-get update \
    && apt_retry apt-get install -y --no-install-recommends software-properties-common \
    && add-apt-repository universe \
    && apt_retry apt-get update \
    && apt_retry apt-get install -y --no-install-recommends \
        python3-pip \
    && rm -rf /var/lib/apt/lists/*

# ROS 2 packages from ros2_packages.txt. The osrf/ros:*-desktop base image
# already configures /etc/apt/sources.list.d/ros2.sources with the signed
# keyring, so we do not re-add the repo here.
COPY ros2_packages.txt /tmp/ros2_packages.txt
RUN apt_retry apt-get update \
    && xargs -a /tmp/ros2_packages.txt -I {} bash -c "apt_retry apt-get install -y --no-install-recommends \$(echo {} | sed 's/\${RR_ROS_DISTRO}/$RR_ROS_DISTRO/g')" \
    && rm -rf /var/lib/apt/lists/*


ENV SHELL=/bin/bash

# Set up the ROS 2 environment. Lives in /etc/profile.d for login shells, and
# is pulled in from ~/.bashrc *above* the non-interactive guard so
# `ssh user@host 'cmd'` also inherits ROS. (Debian-patched bash sources
# ~/.bashrc for rshd/sshd-style non-interactive invocations and ignores
# BASH_ENV in that mode, so prepending the source is the reliable path.)
USER root
RUN printf '%s\n' \
    'if [ -z "$ROS_DISTRO" ]; then' \
    '    source /opt/ros/'"${RR_ROS_DISTRO}"'/setup.bash' \
    '    [ -f /ros2_ws/install/setup.bash ] && source /ros2_ws/install/setup.bash' \
    'fi' \
    > /etc/profile.d/ros.sh \
    && chmod 644 /etc/profile.d/ros.sh
USER ${RR_USERNAME}
RUN touch ${HOME}/.bashrc && sed -i '1i source /etc/profile.d/ros.sh' ${HOME}/.bashrc

WORKDIR /ros2_ws

# SSH configuration - capability is always baked in; the service is started
# (or not) at runtime from scripts/run.bash based on RR_SSH_ENABLED.
ARG RR_SSH_PORT=20022
USER root
RUN echo Port ${RR_SSH_PORT} >> /etc/ssh/sshd_config

# Create /run/sshd directory and set permissions
RUN mkdir -p /run/sshd && chmod 0755 /run/sshd
USER ${RR_USERNAME}

CMD ["/bin/bash"]
