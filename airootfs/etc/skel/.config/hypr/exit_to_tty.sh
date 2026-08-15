#!/usr/bin/env bash
# Script to cleanly exit Hyprland and drop to TTY1 with no UI resource usage.

if systemctl is-active --quiet sddm; then
    sudo systemctl stop sddm
    sudo systemctl start getty@tty1.service 2>/dev/null
    sudo chvt 1 2>/dev/null
    sudo setterm --term linux --blank 1 --powerdown 1 > /dev/tty1 2>/dev/null
else
    uwsm stop 2>/dev/null || hyprctl dispatch exit
fi
