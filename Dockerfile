ARG ROS_DISTRO=none
ARG SSH_ENABLED=0
FROM osrf/ros:${ROS_DISTRO}-desktop AS base
ARG ROS_DISTRO=none
ARG USERNAME=USERNAME
ARG USER_UID=USER_UID
ARG USER_GID=USER_GID
ARG IMAGE_NAME=IMAGE_NAME

RUN echo "Building..."
RUN echo "+ USERNAME=${USERNAME}" 
RUN echo "+ USER_UID=${USER_UID}"
RUN echo "+ USER_GID=${USER_GID}"


# # # # # # # # # # # # # # # # # # # #
# Create the user with same GID and UID as the host:
# # # # # # # # # # #  # # # # # # # # 
# Change the primary group of any user using the group to be deleted
RUN if getent group ${USER_GID}; then \
    for user in $(getent passwd | awk -F: -v gid=${USER_GID} '$4 == gid {print $1}'); do \
    usermod -g users $user; \
    done; \
    fi

# Delete existing user if it exists
RUN if getent passwd ${USER_UID}; then \
    userdel -r $(getent passwd ${USER_UID} | cut -d: -f1); \
    fi

# Delete existing group if it exists
RUN if getent group ${USER_GID}; then \
    groupdel $(getent group ${USER_GID} | cut -d: -f1); \
    fi

# Create the group with the specified GID
RUN groupadd -g ${USER_GID} ${USERNAME}

# Create the user with the specified UID and add to the sudo group
RUN useradd -m -u ${USER_UID} -g ${USER_GID} -s /bin/bash ${USERNAME} \
    && usermod -aG sudo ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
# # # # # # # # # # # # # # # # # # # # # 

# Python install
RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y python3-pip

RUN apt update && apt install -y inetutils-tools net-tools ssh

# Set up the ROS 2 repository and install the packages listed in included ros2_packages.txt
COPY ros2_packages.txt /tmp/ros2_packages.txt
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add - \
    && sh -c 'echo "deb http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" > /etc/apt/sources.list.d/ros2-latest.list' \
    && apt-get update \
    &&xargs -a /tmp/ros2_packages.txt -I {} bash -c "apt-get install -y \$(echo {} | sed 's/\${ROS_DISTRO}/$ROS_DISTRO/g')" \
    && rm -rf /var/lib/apt/lists/*


ENV SHELL=/bin/bash

# Set up the ROS 2 environment
USER ${USERNAME}
RUN echo source /opt/ros/${ROS_DISTRO}/setup.bash >> ${HOME}/.bashrc

WORKDIR /ros2_ws

FROM base AS ssh-branch-0

CMD ["/bin/bash"]

FROM base AS ssh-branch-1
ARG SSH_PORT

# Set up ssh access
USER root
RUN echo Port ${SSH_PORT} >> /etc/ssh/sshd_config

# Create /run/sshd directory and set permissions
RUN mkdir -p /run/sshd && chmod 0755 /run/sshd
USER ${USERNAME}

CMD sudo service ssh start \
    && echo "SSH access enabled, connect with:" \
    && echo "ssh -l $(whoami) -p $(tail -n 1 /etc/ssh/sshd_config | cut -d ' ' -f 2) $(hostname -I | cut -d ' ' -f 1)" \
    && /bin/bash

FROM ssh-branch-${SSH_ENABLED} AS final
RUN echo "Built image with SSH_ENABLED=${SSH_ENABLED}" 