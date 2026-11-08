#!/bin/sh
set -e

sudo apt update

# sway: tiling wayland compositor / window manager
# foot: lightweight terminal
# fuzzel: application launcher
# waybar: status bar
# pavucontrol: pulseaudio/pipewire volume control GUI
# blueman: bluetooth manager
# wireplumber: pipewire session manager
# brightnessctl: brightness control
# grim: screenshot tool
# slurp: screen region selector (used with grim)
# wl-clipboard: wl-copy/wl-paste clipboard utilities
# dunst: notification daemon
# swaylock: screen locker
# swayidle: idle manager (auto-lock, display off)
# swaybg: wallpaper setter
# wev: wayland event/key viewer for debugging keybindings
# network-manager: network management (provides nmtui for waybar)
sudo apt install -y \
  sway \
  foot \
  fuzzel \
  waybar \
  pavucontrol \
  blueman \
  wireplumber \
  brightnessctl \
  grim \
  slurp \
  wl-clipboard \
  dunst \
  swaylock \
  swayidle \
  swaybg \
  wev \
  network-manager

# allow user to control display brightness
if ! id -nG "$USER" | grep -qw video; then
  sudo usermod -aG video "$USER"
  echo "Log out and back in for the video group to apply"
fi

# nerd font needed for waybar icons
if ! fc-list | grep -qi "MesloLGLDZ.*Nerd"; then
  echo "Missing font: MesloLGLDZNerdFont-Regular.ttf (put in ~/.fonts, then run fc-cache -f)"
fi
