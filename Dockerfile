ARG ROS_DISTRO=jazzy
FROM osrf/ros:${ROS_DISTRO}-desktop
ARG ROS_DISTRO
ARG USERNAME=USERNAME
ARG USER_UID=USER_UID
ARG USER_GID=USER_GID
ARG IMAGE_NAME=IMAGE_NAME

RUN echo "Building..."
RUN echo "+ USERNAME=${USERNAME}" 
RUN echo "+ USER_UID=${USER_UID}"
RUN echo "+ USER_GID=${USER_GID}"

# the following is to allow full compatibility with the host system's file permissions:
# Remove existing user with the same UID if it exists
RUN if id -u ${USER_UID} >/dev/null 2>&1; then \
        existing_user=$(getent passwd ${USER_UID} | cut -d: -f1); \
        userdel -r ${existing_user}; \
    fi

# Create the user and group
RUN if ! getent group ${USER_GID}; then \
        groupadd --gid ${USER_GID} ${USERNAME}; \
    fi \
    && useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME};


RUN apt-get update \
    && apt-get install -y sudo \
    && echo ${USERNAME} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}
    
RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y python3-pip

RUN apt update && apt install -y inetutils-tools net-tools

ENV SHELL=/bin/bash
# RUN echo "HOME=${HOME}"
RUN cat /etc/passwd

USER ${USERNAME}

RUN bash -c "echo source /opt/ros/${ROS_DISTRO}/setup.bash >> ~/.bashrc"
WORKDIR /ros2_ws
CMD ["/bin/bash"]
