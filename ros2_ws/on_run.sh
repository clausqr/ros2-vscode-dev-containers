#!/bin/bash
#
# Runs once at container start (sourced by scripts/run.bash). Customise it to
# set up the workspace and to make env available to SSH login shells. Safe to
# delete if you don't need a startup hook — run.bash only sources it if present.

echo "Running on_run.sh..."

# Ensure ~/.bashrc sources the ROS env snippet above the non-interactive guard,
# so `ssh user@host 'cmd'` inherits ROS too. The image already does this, but
# when /home is a persistent named volume it masks the image's edit, so we
# re-apply idempotently at start.
if [ -f /etc/profile.d/ros.sh ] && [ -w "$HOME/.bashrc" ] && ! grep -q '/etc/profile.d/ros.sh' "$HOME/.bashrc"; then
    sed -i '1i source /etc/profile.d/ros.sh' "$HOME/.bashrc"
    echo "Patched $HOME/.bashrc to source /etc/profile.d/ros.sh"
fi

# Materialise DDS / RMW env into /etc/profile.d so SSH login shells inherit it.
# Docker's -e flags reach PID 1 (and interactive shells) but PAM strips them
# from SSH-spawned login shells, so we re-emit the values the container was
# started with into a system-scoped profile snippet. Only the vars that are
# actually set get emitted, so this is a no-op when DDS containment is off.
if [ -n "${FASTRTPS_DEFAULT_PROFILES_FILE:-}${RMW_IMPLEMENTATION:-}${CYCLONEDDS_URI:-}${ROS_LOCALHOST_ONLY:-}" ]; then
    sudo tee /etc/profile.d/dds-env.sh > /dev/null <<EOF
# Written by /ros2_ws/on_run.sh at container start from docker -e values.
${FASTRTPS_DEFAULT_PROFILES_FILE:+export FASTRTPS_DEFAULT_PROFILES_FILE=$FASTRTPS_DEFAULT_PROFILES_FILE}
${CYCLONEDDS_URI:+export CYCLONEDDS_URI=$CYCLONEDDS_URI}
${ROS_LOCALHOST_ONLY:+export ROS_LOCALHOST_ONLY=$ROS_LOCALHOST_ONLY}
${RMW_IMPLEMENTATION:+export RMW_IMPLEMENTATION=$RMW_IMPLEMENTATION}
EOF
    sudo chmod 644 /etc/profile.d/dds-env.sh
    echo "Wrote /etc/profile.d/dds-env.sh (DDS profiles + RMW + localhost-only)"

    if [ -w "$HOME/.bashrc" ] && ! grep -q '/etc/profile.d/dds-env.sh' "$HOME/.bashrc"; then
        sed -i '1i source /etc/profile.d/dds-env.sh' "$HOME/.bashrc"
        echo "Patched $HOME/.bashrc to source /etc/profile.d/dds-env.sh"
    fi
fi

# You can add your own startup commands here.

# Build the workspace if it hasn't been built yet, then source it. Tolerant of
# an empty template workspace (no packages) so it never blocks sshd from coming
# up on first start.
if [ -f "/ros2_ws/install/setup.bash" ]; then
    echo "Sourcing /ros2_ws/install/setup.bash"
    source /ros2_ws/install/setup.bash
else
    echo "No install/setup.bash found; building workspace with colcon..."
    cd /ros2_ws
    source "/opt/ros/${ROS_DISTRO:-humble}/setup.bash"
    colcon build --symlink-install || echo "colcon build reported no packages / failed; continuing"
    [ -f /ros2_ws/install/setup.bash ] && source /ros2_ws/install/setup.bash
fi

echo "on_run.sh completed!"
