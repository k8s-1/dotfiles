#!/bin/sh
choice=$(printf 'Lock\nLogout\nRestart\nShutdown\n' | fuzzel --dmenu --prompt='Power: ' --font='DejaVu Sans:size=16' --width=24 --lines=4)
case "$choice" in
  Lock) swaylock -f -c 000000 ;;
  Logout) swaymsg exit ;;
  Restart) systemctl reboot ;;
  Shutdown) systemctl poweroff ;;
esac
