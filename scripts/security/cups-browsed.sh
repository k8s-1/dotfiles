#!/usr/bin/env bash
set -e

if [ "$KEEP_CUPS_BROWSED" = "enable" ]; then
  action=enable
  snap_action=start
else
  action=disable
  snap_action=stop
fi

if systemctl cat cups-browsed.service >/dev/null 2>&1; then
  sudo systemctl "$action" --now cups-browsed.service
fi

if command -v snap >/dev/null && snap list cups >/dev/null 2>&1; then
  sudo snap "$snap_action" "--$action" cups.cups-browsed
fi
