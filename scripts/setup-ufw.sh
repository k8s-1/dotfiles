#!/usr/bin/env bash
set -e

if ! dpkg -s ufw 2>/dev/null | grep -q '^Status: install ok installed'; then
  sudo apt update
  sudo apt install -y ufw
fi

sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw default deny routed
sudo ufw logging low

sudo ufw --force enable
sudo systemctl enable ufw
sudo ufw status verbose
