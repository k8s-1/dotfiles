#!/usr/bin/env bash
set -e

sudo apt update

packages=(
  stow            # symlink dotfiles
  tmux            # terminal multiplexer
  fzf             # fuzzy finder (used by bashrc and justfile)
  jq              # json processor (used by justfile)
  golang-go       # go toolchain
  just            # task runner
  build-essential # make, gcc tooling
)

for pkg in "${packages[@]}"; do
  if dpkg -s "$pkg" 2>/dev/null | grep -q '^Status: install ok installed'; then
    continue
  else
    sudo apt install -y "$pkg"
  fi
done
