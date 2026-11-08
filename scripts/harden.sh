#!/usr/bin/env bash
set -e

# setup ufw

if ! dpkg -s ufw 2>/dev/null | grep -q '^Status: install ok installed'; then
  sudo apt update
  sudo apt install -y ufw usbguard
fi

sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw default deny routed
sudo ufw logging low

sudo ufw --force enable
sudo systemctl enable ufw
sudo ufw status verbose

# disable ssh

sudo systemctl disable --now ssh.service ssh.socket sshd.service 2>/dev/null || true
sudo systemctl mask ssh.service ssh.socket sshd.service

# kernel hardening

sudo tee /etc/sysctl.d/98-hardening.conf >/dev/null <<'EOF'
kernel.kptr_restrict=2
kernel.dmesg_restrict=1
kernel.yama.ptrace_scope=1
kernel.unprivileged_bpf_disabled=1
net.core.bpf_jit_harden=2
fs.protected_hardlinks=1
fs.protected_symlinks=1
fs.protected_fifos=2
fs.protected_regular=2
net.ipv4.tcp_syncookies=1
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv4.conf.all.accept_source_route=0
net.ipv4.conf.default.accept_source_route=0
net.ipv6.conf.all.accept_redirects=0
net.ipv6.conf.default.accept_redirects=0
net.ipv6.conf.all.accept_source_route=0
net.ipv6.conf.default.accept_source_route=0
net.ipv4.icmp_echo_ignore_broadcasts=1
EOF
sudo sysctl --system >/dev/null

# unattended upgrades

if ! dpkg -s unattended-upgrades 2>/dev/null | grep -q '^Status: install ok installed'; then
  sudo apt install -y unattended-upgrades
fi
sudo systemctl enable --now unattended-upgrades
