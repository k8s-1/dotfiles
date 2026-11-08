#!/usr/bin/env bash
set -e

if [ "$(id -u)" -eq 0 ]; then
  echo "run as a regular user, not root" >&2
  exit 1
fi

sudo apt update
sudo apt install -y uidmap dbus-user-session docker-ce-rootless-extras

user=$(id -un)
grep -q "^${user}:" /etc/subuid || sudo usermod --add-subuids 100000-165535 "$user"
grep -q "^${user}:" /etc/subgid || sudo usermod --add-subgids 100000-165535 "$user"

sudo systemctl disable --now docker.service docker.socket
sudo rm -f /var/run/docker.sock

if [ ! -f "$HOME/.config/systemd/user/docker.service" ]; then
  dockerd-rootless-setuptool.sh install
fi
systemctl --user enable --now docker.service

if [ "$(loginctl show-user "$user" -p Linger --value)" != "yes" ]; then
  sudo loginctl enable-linger "$user"
fi

docker context use rootless >/dev/null
docker info --format '{{.SecurityOptions}}'
