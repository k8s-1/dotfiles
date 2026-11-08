#!/usr/bin/env bash
set -e

if ! systemctl is-active --quiet bluetooth.service; then
  echo "bluetooth: service not active, skipped"
  exit 0
fi

# discoverable is only needed when another device must find this laptop, e.g. file transfer from other machine, this is not needed for pairing
# pairable is only needed while pairing a new device: bluetoothctl pairable on
bluetoothctl pairable off
bluetoothctl discoverable off
bluetoothctl show | grep -E 'Discoverable|Pairable'
