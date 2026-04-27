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
# Create the user with same GID and UID as the host:
# # # # # # # # # # #  # # # # # # # #
# Change the primary group of any user using the group to be deleted
RUN if getent group ${RR_USER_GID}; then \
    for user in $(getent passwd | awk -F: -v gid=${RR_USER_GID} '$4 == gid {print $1}'); do \
    usermod -g users $user; \
    done; \
    fi

# Delete existing user if it exists
RUN if getent passwd ${RR_USER_UID}; then \
    userdel -r $(getent passwd ${RR_USER_UID} | cut -d: -f1); \
    fi

# Delete existing group if it exists
RUN if getent group ${RR_USER_GID}; then \
    groupdel $(getent group ${RR_USER_GID} | cut -d: -f1); \
    fi

# Create the group with the specified GID
RUN groupadd -g ${RR_USER_GID} ${RR_USERNAME}

# Create the user with the specified UID and add to the sudo group
RUN useradd -m -u ${RR_USER_UID} -g ${RR_USER_GID} -s /bin/bash ${RR_USERNAME} \
    && usermod -aG sudo ${RR_USERNAME} \
    && echo "${RR_USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
# # # # # # # # # # # # # # # # # # # # #

# Retry wrapper for transient DNS / mirror failures during build.
# Usage: apt_retry <apt-get args...>
RUN printf '#!/bin/sh\nset -e\nfor i in 1 2 3 4 5; do\n  if "$@"; then exit 0; fi\n  echo "apt step failed (attempt $i), retrying in 5s..." >&2\n  sleep 5\ndone\nexit 1\n' > /usr/local/bin/apt_retry && chmod +x /usr/local/bin/apt_retry

# Python install. universe is required for python3-pip on Ubuntu Jammy.
RUN apt_retry apt-get update \
    && apt_retry apt-get install -y software-properties-common \
    && add-apt-repository universe \
    && apt_retry apt-get update \
    && apt_retry apt-get upgrade -y \
    && apt_retry apt-get install -y python3-pip

RUN apt_retry apt-get update && apt_retry apt-get install -y inetutils-tools net-tools ssh

# Set up the ROS 2 repository and install the packages listed in included ros2_packages.txt
COPY ros2_packages.txt /tmp/ros2_packages.txt
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add - \
    && sh -c 'echo "deb http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" > /etc/apt/sources.list.d/ros2-latest.list' \
    && apt-get update \
    &&xargs -a /tmp/ros2_packages.txt -I {} bash -c "apt-get install -y \$(echo {} | sed 's/\${RR_ROS_DISTRO}/$RR_ROS_DISTRO/g')" \
    && rm -rf /var/lib/apt/lists/*


ENV SHELL=/bin/bash

# Set up the ROS 2 environment
USER ${RR_USERNAME}
RUN echo source /opt/ros/${RR_ROS_DISTRO}/setup.bash >> ${HOME}/.bashrc

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
