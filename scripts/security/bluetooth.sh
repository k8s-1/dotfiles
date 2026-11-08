#!/usr/bin/env bash
set -e

if ! systemctl is-active --quiet bluetooth.service; then
  echo "bluetooth: service not active, skipped"
  exit 0
fi

# discoverable is only needed when another device must find this laptop
# (phone scanning for it, file transfer from another machine).
# pairing a headset/mouse/keyboard from the laptop does not need it:
# put the accessory in pairing mode and scan from here.
# pairable is only needed while pairing a new device: bluetoothctl pairable on
# reconnecting an already paired device needs neither.
bluetoothctl pairable off
bluetoothctl discoverable off
bluetoothctl show | grep -E 'Discoverable|Pairable'
