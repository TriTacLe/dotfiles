#!/bin/bash

set -euo pipefail

if ! upower -e | grep -q "battery"; then
  exit 0
fi

BATTERY_PATH=$(upower -e | grep -m1 battery)
BATTERY_PERCENT=$(upower -i "$BATTERY_PATH" | grep percentage | awk '{print $2}' | tr -d '%')
BATTERY_STATE=$(upower -i "$BATTERY_PATH" | grep state | awk '{print $2}')

# Wear moves too slowly to see day to day, and charge_full only ever reports
# right now, so a charge cap can only be judged against a recorded trend.
# This timer already fires every 5 min, hence the one-sample-a-day guard.
log_battery_health() {
  local sys full design cycles today log
  set -- /sys/class/power_supply/BAT*
  sys=$1
  [ -d "$sys" ] || return 0

  log="${XDG_STATE_HOME:-$HOME/.local/state}/battery-health.csv"
  today=$(date +%F)
  grep -q "^$today," "$log" 2>/dev/null && return 0

  # Some firmware reports charge in uAh, some energy in uWh. Either one trends
  # the same way, so record whichever exists and note the unit in the row.
  if [ -r "$sys/charge_full" ] && [ -r "$sys/charge_full_design" ]; then
    full=$(cat "$sys/charge_full"); design=$(cat "$sys/charge_full_design")
  elif [ -r "$sys/energy_full" ] && [ -r "$sys/energy_full_design" ]; then
    full=$(cat "$sys/energy_full"); design=$(cat "$sys/energy_full_design")
  else
    return 0
  fi
  [ "$design" -gt 0 ] 2>/dev/null || return 0
  cycles=$(cat "$sys/cycle_count" 2>/dev/null || echo 0)

  mkdir -p "$(dirname "$log")"
  [ -s "$log" ] || echo "date,full,design,cycles,health_pct" > "$log"
  awk -v d="$today" -v f="$full" -v n="$design" -v c="$cycles" \
    'BEGIN { printf "%s,%s,%s,%s,%.2f\n", d, f, n, c, 100*f/n }' >> "$log"
}

log_battery_health

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
