#!/usr/bin/env bash
set -e
source "$(dirname "$0")/../lib/common.sh"

# quad9 secure dns https://quad9.net/

cat >"$tmp" <<'EOF'
[Resolve]
DNS=9.9.9.9#dns.quad9.net 149.112.112.112#dns.quad9.net 2620:fe::fe#dns.quad9.net 2620:fe::9#dns.quad9.net
DNSOverTLS=yes
Domains=~.
EOF

if install_if_changed /etc/systemd/resolved.conf.d/dot.conf; then
  sudo systemctl restart systemd-resolved
fi
