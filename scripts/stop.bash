#!/usr/bin/env bash
# 
# DESCRIPTION:
#   If the container is running, it stops it.
#
# USAGE:
#   To use this script, run:
#     rr stop [--name <container_name>]
#
# OPTIONS:
#       --name:  The name of the container to stop. If not provided, the default
#                container name from setup.env will be used.




source setup.env

# Default value
default_container_name=$IMAGE_NAME

# Parse command line arguments, add your own arguments here
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --name)
            container_name="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [--name <container_name>]"
            exit 0
            ;;
        *)
            echo "Unknown parameter passed: $1"
            exit 1
            ;;
    esac
done

# Use the default value if no --name argument was passed
container_name="${container_name:-$default_container_name}"

echo "Stopping ${container_name}...

docker stop ${container_name}
echo "${container_name} stopped OK"