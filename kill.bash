#!/usr/bin/env bash
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
        *)
            echo "Unknown parameter passed: $1"
            exit 1
            ;;
    esac
done

# Use the default value if no --name argument was passed
container_name="${container_name:-$default_container_name}"

echo "Killing ${container_name}...

docker kill ${container_name}
echo "${container_name} killed OK"