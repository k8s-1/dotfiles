#!/usr/bin/env bash
set -e

units=(
  avahi-daemon.socket
  avahi-daemon.service
  apport-forward.socket
  apport.service
  ModemManager.service
  iscsid.socket
  open-iscsi.service
  postfix.service
)

if [ "$KEEP_SERVICES" = "enable" ]; then
  action=enable
else
  action=disable
fi

for u in "${units[@]}"; do
  if systemctl cat "$u" >/dev/null 2>&1; then
    sudo systemctl "$action" --now "$u"
  fi
done
