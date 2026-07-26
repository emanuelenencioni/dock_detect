#!/bin/bash
# Intercepts lid close/open events when at home desk

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

IS_HOME_SCRIPT="/usr/local/bin/is_home_desk.sh"
INHIBIT_PID_FILE="/tmp/dock_detect_inhibit.pid"

STATE=$(cat /proc/acpi/button/lid/*/state 2>/dev/null | awk '{print $2}')

if [ "$STATE" = "closed" ] && $IS_HOME_SCRIPT; then
    hyprctl keyword monitor eDP-1,disable
    systemd-inhibit --what=sleep --why='Docked at home — lid closed' sleep infinity &
    echo $! > "$INHIBIT_PID_FILE"

elif [ "$STATE" = "open" ] && $IS_HOME_SCRIPT; then
    hyprctl keyword monitor eDP-1,preferred,-2560x0,1
    if [ -f "$INHIBIT_PID_FILE" ]; then
        kill "$(cat $INHIBIT_PID_FILE)" 2>/dev/null
        rm -f "$INHIBIT_PID_FILE"
    fi
fi
