#!/bin/bash
# Called by udev when the home USB-C hub connects/disconnects
# $1 = "add" or "remove"

USER="YOUR_USERNAME"

# Find the Hyprland instance signature dynamically
HYPR_DIR=$(ls -d /run/user/$(id -u $USER)/hypr/*/ 2>/dev/null | head -1)
INSTANCE_SIG=$(basename "$HYPR_DIR" 2>/dev/null)

if [ -z "$INSTANCE_SIG" ]; then
    # Try alternative location
    HYPR_DIR=$(ls -d /tmp/hypr/*/ 2>/dev/null | head -1)
    INSTANCE_SIG=$(basename "$HYPR_DIR" 2>/dev/null)
fi

export XDG_RUNTIME_DIR="/run/user/$(id -u $USER)"
export HYPRLAND_INSTANCE_SIGNATURE="$INSTANCE_SIG"

IS_HOME_SCRIPT="/usr/local/bin/is_home_desk.sh"

if [ "$1" = "add" ] && $IS_HOME_SCRIPT; then
    hyprctl keyword monitor eDP-1,disable
    hyprctl keyword monitor DP-3,2560x1440@180,0x0,1

    HDMI_EDID=$(md5sum /sys/class/drm/card1-HDMI-A-1/edid 2>/dev/null | cut -d' ' -f1)
    if [ -n "$HDMI_EDID" ] && [ "$HDMI_EDID" != "d41d8cd98f00b204e9800998ecf8427e" ]; then
        hyprctl keyword monitor HDMI-A-1,preferred,2560x0,1
    fi

elif [ "$1" = "remove" ]; then
    hyprctl keyword monitor eDP-1,preferred,0x0,1
fi
