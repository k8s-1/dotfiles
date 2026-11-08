#!/usr/bin/env bash
set -e

sudo apt update

packages=(
  sway                   # tiling wayland compositor / window manager
  foot                   # lightweight terminal
  fuzzel                 # application launcher
  waybar                 # status bar
  pavucontrol            # pulseaudio/pipewire volume control GUI
  blueman                # bluetooth manager
  wireplumber            # pipewire session manager
  brightnessctl          # brightness control
  grim                   # screenshot tool
  slurp                  # screen region selector (used with grim)
  wl-clipboard           # wl-copy/wl-paste clipboard utilities
  dunst                  # notification daemon
  swaylock               # screen locker
  swayidle               # idle manager (auto-lock, display off)
  swaybg                 # wallpaper setter
  wev                    # wayland event/key viewer for debugging keybindings
  network-manager        # network management (provides nmtui for waybar)
  libnotify-bin          # notify-send for mic mute notifications
  papirus-icon-theme     # icon theme for fuzzel and dunst
  pipewire               # audio/video server
  pipewire-pulse         # PulseAudio compatibility (needed by pavucontrol and waybar)
  xdg-desktop-portal-wlr # screen sharing and camera/mic portal for sway
  usbguard               # USB device authorization policy
)

for pkg in "${packages[@]}"; do
  if dpkg -s "$pkg" 2>/dev/null | grep -q '^Status: install ok installed'; then
    continue
  else
    sudo apt install -y "$pkg"
  fi
done

# allow user to control display brightness
if ! id -nG "$USER" | grep -qw video; then
  sudo usermod -aG video "$USER"
  echo "Log out and back in for the video group to apply"
fi

# nerd font needed for waybar icons
if ! fc-list | grep -qi "MesloLGLDZ.*Nerd"; then
  echo "Missing font: MesloLGLDZNerdFont-Regular.ttf (put in ~/.fonts, then run fc-cache -f)"
fi

# set default browser only if unset: firefox (snap), firefox, chromium (snap), chromium
for desktop in firefox_firefox.desktop firefox.desktop chromium_chromium.desktop chromium.desktop; do
  if [ -n "$(xdg-settings get default-web-browser 2>/dev/null)" ]; then
    break
  elif
    [ -f "/usr/share/applications/$desktop" ] ||
      [ -f "/var/lib/snapd/desktop/applications/$desktop" ] ||
      [ -f "$HOME/.local/share/applications/$desktop" ]
  then
    xdg-settings set default-web-browser "$desktop"
    break
  fi
done
