#!/usr/bin/env bash
source setup.env

# Default value
default_instance_name=$IMAGE_NAME

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --name)
            instance_name="$2"
            shift 2
            ;;
        *)
            echo "Unknown parameter passed: $1"
            exit 1
            ;;
    esac
done

# Use the default value if no --name argument was passed
instance_name="${instance_name:-$default_instance_name}"

echo "Running image $IMAGE_NAME using USERNAME=$USERNAME USER_UID=$USER_UID USER_GID=$USER_GID"
echo "Container will be named $instance_name"
echo 

docker run -it \
   --rm \
   --gpus=all \
   --net=host \
   --user $USER_UID:$USER_GID \
   -e DISPLAY=$DISPLAY \
   -v /tmp/.X11-unix:/tmp/.X11-unix \
   -v /dev/dri:/dev/dri \
   -v /dev/shm:/dev/shm \
   -v $(pwd)/ros2_ws:/ros2_ws \
   --name $instance_name \
   $IMAGE_NAME