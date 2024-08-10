#!/bin/bash

# rosdep update --rosdistro ${ROS_DISTRO}
# rosdep install --from-paths /ros2_ws/src --ignore-src -r -y --rosdistro ${ROS_DISTRO}
    
# Build the ROS 2 workspace
colcon build 
source /ros2_ws/install/setup.bash