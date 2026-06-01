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

# Python install
RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y python3-pip

RUN apt update && apt install -y inetutils-tools net-tools ssh

# Install the ROS 2 packages listed in ros2_packages.txt. The osrf/ros base
# image already ships /etc/apt/sources.list.d/ros2.sources with the keyring set
# up, so the old manual ros.asc apt-key + ros2-latest.list was a duplicate that
# triggered "configured multiple times" warnings (and apt-key is deprecated).
COPY ros2_packages.txt /tmp/ros2_packages.txt
RUN apt-get update \
    && xargs -a /tmp/ros2_packages.txt -I {} bash -c "apt-get install -y \$(echo {} | sed 's/\${RR_ROS_DISTRO}/$RR_ROS_DISTRO/g')" \
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
RUN sed -i '1i source /etc/profile.d/ros.sh' ${HOME}/.bashrc

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
