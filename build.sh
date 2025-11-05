#!/usr/bin/env bash
set -euo pipefail

# Convenience wrapper that ensures dependencies exist before running the main customization script.

required_packages=(android-sdk-libsparse-utils e2fsprogs unzip curl)
missing=()
for pkg in "${required_packages[@]}"; do
  if ! dpkg -s "$pkg" >/dev/null 2>&1; then
    missing+=("$pkg")
  fi
done

if [ ${#missing[@]} -ne 0 ]; then
  echo "[NekoOS] Installing missing packages: ${missing[*]}"
  sudo apt-get update
  sudo apt-get install -y "${missing[@]}"
fi

sudo scripts/customize_gsi.sh "$@"
