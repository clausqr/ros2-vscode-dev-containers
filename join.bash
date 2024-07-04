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

echo "Joining running container $instance_name using USERNAME=$USERNAME USER_UID=$USER_UID USER_GID=$USER_GID"

docker exec -it $instance_name bash