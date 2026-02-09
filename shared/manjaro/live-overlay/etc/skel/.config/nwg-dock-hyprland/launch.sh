#!/usr/bin/env bash
#    ___           __
#   / _ \___  ____/ /__
#  / // / _ \/ __/  '_/
# /____/\___/\__/_/\_\
#

DOCK_CONFIG="style.css"
AUTOHIDE="false"
case "$1" in
autohide)
  AUTOHIDE="true"
  ;;
default)
  AUTOHIDE="false"
  ;;
esac

killall nwg-dock-hyprland
sleep 0.5

if [ AUTOHIDE=="true" ]; then
  nwg-dock-hyprland -d -i 32 -w 5 -mb 10 -x -s $DOCK_CONFIG &
else
  nwg-dock-hyprland -i 32 -w 5 -mb 10 -x -s $DOCK_CONFIG &
fi
