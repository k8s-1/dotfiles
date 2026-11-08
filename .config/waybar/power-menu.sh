#!/bin/sh
choice=$(printf 'Lock\nLogout\nRestart\nShutdown\n' | fuzzel --dmenu --config="$HOME/.config/waybar/power-menu.ini")
case "$choice" in
  Lock) swaylock -f -c 000000 ;;
  Logout) swaymsg exit ;;
  Restart) systemctl reboot ;;
  Shutdown) systemctl poweroff ;;
esac
