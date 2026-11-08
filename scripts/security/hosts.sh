#!/usr/bin/env bash
set -e
source "$(dirname "$0")/../lib/common.sh"

hosts=/etc/hosts
begin="# BEGIN dotfiles harden.sh managed block"
end="# END dotfiles harden.sh managed block"

if [ ! -f "$hosts.orig" ]; then
  sudo cp -p "$hosts" "$hosts.orig"
fi

sed "/^$begin\$/,/^$end\$/d" "$hosts" >"$tmp"

{
  echo "$begin"
  cat <<'EOF'
# Time wasters
# 4-hours of leisure based screentime
# is directly linked with dementia
0.0.0.0 chess.com
0.0.0.0 www.chess.com
0.0.0.0 lichess.com
0.0.0.0 www.lichess.com
0.0.0.0 lichess.org

# Privacy trackers & ads
0.0.0.0 www.google-analytics.com
0.0.0.0 google-analytics.com
0.0.0.0 ssl.google-analytics.com
0.0.0.0 analytics.google.com
0.0.0.0 pagead2.googlesyndication.com
0.0.0.0 ad.doubleclick.net
0.0.0.0 connect.facebook.net
0.0.0.0 graph.facebook.com
0.0.0.0 facebook.com
0.0.0.0 staticxx.facebook.com
0.0.0.0 vortex.data.microsoft.com
0.0.0.0 telemetry.microsoft.com
0.0.0.0 watson.telemetry.microsoft.com
0.0.0.0 settings-win.data.microsoft.com
0.0.0.0 telemetry.mozilla.org
0.0.0.0 metrics.apple.com
0.0.0.0 tiktok.com
0.0.0.0 www.tiktok.com
0.0.0.0 analytics.tiktok.com
0.0.0.0 ads.yahoo.com
0.0.0.0 adserver.snapchat.com
0.0.0.0 ads.twitter.com
0.0.0.0 cdn.adsafeprotected.com
# Fonts blocking
0.0.0.0 fonts.googleapis.com
0.0.0.0 fonts.gstatic.com
EOF
  echo "$end"
} >>"$tmp"

if install_if_changed "$hosts" 644; then
  echo "hosts: updated"
fi
