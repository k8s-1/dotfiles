tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

apt_install() {
  local missing=() p
  for p in "$@"; do
    dpkg -s "$p" 2>/dev/null | grep -q '^Status: install ok installed' || missing+=("$p")
  done
  if [ "${#missing[@]}" -gt 0 ]; then
    sudo apt update
    sudo apt install -y "${missing[@]}"
  fi
}

install_if_changed() {
  local dest=$1 mode=${2:-644}
  sudo install -d -m 755 "$(dirname "$dest")"
  if sudo cmp -s "$tmp" "$dest"; then
    return 1
  fi
  sudo install -m "$mode" "$tmp" "$dest"
}
