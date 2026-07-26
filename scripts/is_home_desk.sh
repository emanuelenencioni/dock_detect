#!/bin/bash
# Returns 0 (success) if the home desk monitor is detected via serial number
# Returns 1 (failure) otherwise

USER="YOUR_USERNAME"

# Find the Hyprland instance signature dynamically
HYPR_DIR=$(ls -d /run/user/$(id -u $USER)/hypr/*/ 2>/dev/null | head -1)
INSTANCE_SIG=$(basename "$HYPR_DIR" 2>/dev/null)

if [ -z "$INSTANCE_SIG" ]; then
    HYPR_DIR=$(ls -d /tmp/hypr/*/ 2>/dev/null | head -1)
    INSTANCE_SIG=$(basename "$HYPR_DIR" 2>/dev/null)
fi

export XDG_RUNTIME_DIR="/run/user/$(id -u $USER)"
export HYPRLAND_INSTANCE_SIGNATURE="$INSTANCE_SIG"

HOME_SERIAL="YOUR_MONITOR_SERIAL"

hyprctl monitors all -j 2>/dev/null | grep -q "$HOME_SERIAL"
  
