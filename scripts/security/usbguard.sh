#!/usr/bin/env bash
set -e
source "$(dirname "$0")/../lib/common.sh"

apt_install usbguard

conf=/etc/usbguard/usbguard-daemon.conf

if ! sudo grep -Eq '^ImplicitPolicyTarget=block\s*$' "$conf"; then
  echo "usbguard: ImplicitPolicyTarget is not 'block' in $conf" >&2
  sudo grep -E '^ImplicitPolicyTarget' "$conf" >&2 || echo "usbguard: ImplicitPolicyTarget not set" >&2
  exit 1
fi

if ! systemctl is-enabled --quiet usbguard.service || ! systemctl is-active --quiet usbguard.service; then
  echo "usbguard: service is not enabled and running" >&2
  exit 1
fi

echo "usbguard: ok"
