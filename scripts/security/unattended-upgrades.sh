#!/usr/bin/env bash
set -e
source "$(dirname "$0")/../lib/common.sh"

pkg_install unattended-upgrades

cat >"$tmp" <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF

install_if_changed /etc/apt/apt.conf.d/20auto-upgrades || true
sudo systemctl enable --now unattended-upgrades apt-daily.timer apt-daily-upgrade.timer
