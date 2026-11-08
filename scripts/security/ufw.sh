#!/usr/bin/env bash
set -e
source "$(dirname "$0")/../lib/common.sh"

apt_install ufw

status=$(sudo ufw status verbose)

if ! grep -q '^Default: deny (incoming), allow (outgoing), disabled (routed)$' <<<"$status"; then
  sudo ufw default deny incoming
  sudo ufw default allow outgoing
  sudo ufw default deny routed
fi

if ! grep -q '^Logging: on (low)' <<<"$status"; then
  sudo ufw logging low
fi

if ! grep -q '^Status: active' <<<"$status"; then
  sudo ufw --force enable
fi

sudo systemctl enable ufw
sudo ufw status verbose
