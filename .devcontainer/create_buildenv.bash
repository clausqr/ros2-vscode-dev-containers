#!/bin/bash

# Default values from the environment
INPUT_USERNAME=$(whoami)
USER_UID=$(id -u)
USER_GID=$(id -g)

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --user) INPUT_USERNAME="$2"; shift ;;
        --uid) USER_UID="$2"; shift ;;
        --gid) USER_GID="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Check if the variables are set
if [ -z "$USER_UID" ] || [ -z "$USER_GID" ] || [ -z "$INPUT_USERNAME" ]; then
    echo "Error: USER_UID, USER_GID, or INPUT_USERNAME is not set."
    exit 1
fi

# Create the build.env file and write the variables
cat <<EOF > build.env
USER_UID=$USER_UID
USER_GID=$USER_GID
USERNAME=$INPUT_USERNAME
EOF

# Output the contents of the build.env file
echo "Created build.env with the following contents:"
cat build.env
