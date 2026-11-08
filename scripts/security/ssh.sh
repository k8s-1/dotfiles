#!/usr/bin/env bash
set -e

sudo systemctl disable --now ssh.service ssh.socket sshd.service 2>/dev/null || true
sudo systemctl mask ssh.service ssh.socket sshd.service
