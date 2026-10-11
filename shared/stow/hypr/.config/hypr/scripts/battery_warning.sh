#!/bin/bash

set -euo pipefail

if ! upower -e | grep -q "battery"; then
  exit 0
fi

BATTERY_PATH=$(upower -e | grep -m1 battery)
BATTERY_PERCENT=$(upower -i "$BATTERY_PATH" | grep percentage | awk '{print $2}' | tr -d '%')
BATTERY_STATE=$(upower -i "$BATTERY_PATH" | grep state | awk '{print $2}')

# Per-user runtime dir, not /tmp: fixed names in a world-writable directory mean
# a stale file owned by someone else makes the brightness write fail for good.
STATE_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
# Tracks whether the screen has already been dimmed.
DIMMED_FLAG="$STATE_DIR/battery_dimmed"

# This script only steps the panel further down near empty. The AC and battery
# levels belong to 90-backlight-on-power.rules, which also puts the panel back
# on charge, so there is nothing to save and restore here.
if [ "$BATTERY_STATE" = "discharging" ]; then
  if [ "$BATTERY_PERCENT" -le 5 ]; then
    notify-send -u critical -t 10000 "Kun $BATTERY_PERCENT% igjen!"
    if [ ! -f "$DIMMED_FLAG" ]; then
      brightnessctl set 5%
      touch "$DIMMED_FLAG"
    fi
  elif [ "$BATTERY_PERCENT" -le 10 ]; then
    notify-send -u critical -t 10000 "Batteri lavt: $BATTERY_PERCENT%"
    if [ ! -f "$DIMMED_FLAG" ]; then
      brightnessctl set 15%
      touch "$DIMMED_FLAG"
    fi
  elif [ "$BATTERY_PERCENT" -le 20 ]; then
    notify-send -u normal "Batteri: $BATTERY_PERCENT%"
    if [ ! -f "$DIMMED_FLAG" ]; then
      brightnessctl set 30%
      touch "$DIMMED_FLAG"
    fi
  fi
else
  # The udev rule has already restored the AC level; just clear the flag so the
  # next discharge can dim again.
  if [ -f "$DIMMED_FLAG" ]; then
    rm "$DIMMED_FLAG"
    notify-send -u normal "Lader... Lysstyrke gjenopprettet"
  fi
fi
