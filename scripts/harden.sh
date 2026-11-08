#!/usr/bin/env bash
set -e

dir=$(cd "$(dirname "$0")" && pwd)/security
failed=()

for s in "$dir"/*.sh; do
  name=$(basename "$s")
  echo "==> $name"
  bash "$s" || failed+=("$name")
done

if [ "${#failed[@]}" -gt 0 ]; then
  echo "FAILED: ${failed[*]}" >&2
  exit 1
fi

echo "all ok"
