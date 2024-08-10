#!/bin/bash
# Create a devcontainer.json file from the devcontainer-template.json file by replacing the placeholders with the values from setup.env

# Function to display help
display_help() {
    echo "Usage: $0 [option...] {--username|-u} {--user-uid|-i} {--user-gid|-g} {--image-name|-n}" >&2
    echo
    echo "   -u, --username       Username to replace in the JSON template"
    echo "   -i, --user-uid       User UID to replace in the JSON template"
    echo "   -g, --user-gid       User GID to replace in the JSON template"
    echo "   -n, --image-name     Image name to replace in the JSON template"
    echo
    echo "If no command line arguments are provided, the values from setup.env will be used."
    exit 1
}

# Load the variables from setup.env
source setup.env

# Default values from setup.env
USERNAME_DEFAULT=$USERNAME
USER_UID_DEFAULT=$USER_UID
USER_GID_DEFAULT=$USER_GID
IMAGE_NAME_DEFAULT=$IMAGE_NAME

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -u|--username) USERNAME="$2"; shift ;;
        -i|--user-uid) USER_UID="$2"; shift ;;
        -g|--user-gid) USER_GID="$2"; shift ;;
        -n|--image-name) IMAGE_NAME="$2"; shift ;;
        -h|--help) display_help ;;
        --) shift; break ;;
        -*) echo "Unknown option: $1" >&2; display_help ;;
        *) break ;;
    esac
    shift
done

# Use defaults if not set via command line
USERNAME=${USERNAME:-$USERNAME_DEFAULT}
USER_UID=${USER_UID:-$USER_UID_DEFAULT}
USER_GID=${USER_GID:-$USER_GID_DEFAULT}
IMAGE_NAME=${IMAGE_NAME:-$IMAGE_NAME_DEFAULT}

# Read the JSON template
json_template=$(cat .devcontainer/devcontainer-template.json)

# Replace the placeholders with the actual values
json_template=${json_template//'${templateOption:containerUser}'/$USERNAME}
json_template=${json_template//'${templateOption:containerUid}'/$USER_UID}
json_template=${json_template//'${templateOption:containerGid}'/$USER_GID}

# Output the modified JSON to a new file
echo "$json_template" > .devcontainer/devcontainer.json

echo "Placeholders replaced and output written to .devcontainer/devcontainer.json"
