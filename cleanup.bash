#!/bin/bash

echo Cleaning up ros2_ws artifacts:
echo "Removing ros2_ws/build ros2_ws/install ros2_ws/log"
rm -rf ros2_ws/build 
rm -rf ros2_ws/install
rm -rf ros2_ws/log