#!/usr/bin/env bash
set -e

mapfile -t devices < <(sudo usbguard list-devices -b)

if [ "${#devices[@]}" -eq 0 ]; then
  echo "No blocked devices"
  exit 0
fi

for ((i = 0; i < ${#devices[@]}; i++)); do
  devices[i]+=$'\n'
done

PS3="allow blocked device N) > "
select choice in "${devices[@]}"; do
  [ -n "$choice" ] && break
done

[ -z "$choice" ] && exit 1

id="${choice%%:*}"
echo "$choice"
sudo usbguard allow-device "$id" -p
