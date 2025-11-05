#!/usr/bin/env bash
set -euo pipefail

# Convenience wrapper that ensures dependencies exist before running the main customization script.

required_packages=(
  android-sdk-libsparse-utils
  e2fsprogs
  unzip
  curl
  erofs-utils
  fuse3
  rsync
)
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

chmod +x scripts/customize_gsi.sh

env_args=()
if [ -n "${GSI_FLAVOR:-}" ]; then
  env_args+=("GSI_FLAVOR=${GSI_FLAVOR}")
fi
if [ -n "${GSI_URL:-}" ]; then
  env_args+=("GSI_URL=${GSI_URL}")
fi
if [ -n "${GSI_ZIP:-}" ]; then
  env_args+=("GSI_ZIP=${GSI_ZIP}")
fi
if [ -n "${WORK_DIR:-}" ]; then
  env_args+=("WORK_DIR=${WORK_DIR}")
fi
if [ -n "${OUTPUT_DIR:-}" ]; then
  env_args+=("OUTPUT_DIR=${OUTPUT_DIR}")
fi

sudo env "${env_args[@]}" ./scripts/customize_gsi.sh "$@"
