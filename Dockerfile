FROM osrf/ros:humble-desktop
ARG USERNAME=USERNAME
ARG USER_UID=USER_UID
ARG USER_GID=USER_GID
ARG IMAGE_NAME=IMAGE_NAME

RUN echo "Building..."
RUN echo "+ USERNAME=$USERNAME" 
RUN echo "+ USER_UID=$USER_UID"
RUN echo "+ USER_GID=$USER_GID"
# Create the user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME
RUN apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME
    
RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y python3-pip

RUN apt update && apt install -y inetutils-tools net-tools

ENV SHELL /bin/bash

RUN echo source /opt/ros/humble/setup.bash >> /home/$USERNAME/.bashrc
USER $USERNAME
WORKDIR /ros2_ws/src
CMD ["/bin/bash"]