#!/usr/bin/env bash
set -euo pipefail

# Customization script that patches an official AOSP GSI system image with NekoOS assets.
# Requires sudo for mounting the raw image.

: "${GSI_FLAVOR:=arm64}"  # Supported: arm64 (vanilla), arm64_gms (with Google services)
: "${GSI_URL:=}"
: "${GSI_ZIP:=}"
: "${WORK_DIR:=work}"
: "${OUTPUT_DIR:=output}"

log() {
  echo "[NekoOS] $*"
}

require_tool() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "fatal: required tool '$1' not found" >&2
    exit 1
  fi
}

main() {
  if [ -z "${GSI_URL}" ]; then
    case "${GSI_FLAVOR}" in
      arm64)
        GSI_URL="https://dl.google.com/developers/android/baklava/images/gsi/aosp_arm64-exp-BP41.250916.012.A1-14330953-171efa95.zip"
        ;;
      arm64_gms|gms)
        GSI_URL="https://dl.google.com/developers/android/baklava/images/gsi/gsi_gms_arm64-exp-BP41.250916.012.A1-14330953-45857949.zip"
        ;;
      *)
        echo "fatal: unsupported GSI_FLAVOR '${GSI_FLAVOR}'" >&2
        exit 1
        ;;
    esac
    log "GSI_URL not provided, defaulting to ${GSI_FLAVOR} build"
  else
    log "Using user supplied GSI_URL"
  fi

  if [ -z "${GSI_ZIP}" ]; then
    strip_query="${GSI_URL%%\?*}"
    GSI_ZIP="$(basename "${strip_query}")"
  fi

  require_tool curl
  require_tool unzip
  require_tool simg2img
  require_tool img2simg
  require_tool e2fsck
  require_tool resize2fs

  mkdir -p downloads "${WORK_DIR}" "${OUTPUT_DIR}"

  if [ ! -f "downloads/${GSI_ZIP}" ]; then
    log "Downloading GSI from ${GSI_URL}"
    curl -L "${GSI_URL}" -o "downloads/${GSI_ZIP}"
  else
    log "Using cached downloads/${GSI_ZIP}"
  fi

  if [ ! -f "${WORK_DIR}/system.img" ]; then
    log "Extracting system image"
    unzip -o "downloads/${GSI_ZIP}" system.img -d "${WORK_DIR}"
  fi

  if [ ! -f "${WORK_DIR}/system.raw.img" ]; then
    log "Converting sparse system image to raw"
    simg2img "${WORK_DIR}/system.img" "${WORK_DIR}/system.raw.img"
  fi

  log "Running filesystem check"
  sudo e2fsck -fy "${WORK_DIR}/system.raw.img"

  log "Expanding filesystem to provide customization headroom"
  sudo resize2fs "${WORK_DIR}/system.raw.img" 6144M

  MOUNT_DIR="${WORK_DIR}/mount"
  mkdir -p "${MOUNT_DIR}"
  log "Mounting raw image"
  sudo mount -o loop "${WORK_DIR}/system.raw.img" "${MOUNT_DIR}"

  log "Applying overlays"
  sudo mkdir -p "${MOUNT_DIR}/system/product/overlay/NekoSystemUIOverlay"
  sudo cp -r overlays/NekoSystemUIOverlay/. "${MOUNT_DIR}/system/product/overlay/NekoSystemUIOverlay/"

  if [ -f assets/bootanimation/bootanimation.zip ]; then
    log "Installing custom bootanimation"
    sudo cp assets/bootanimation/bootanimation.zip "${MOUNT_DIR}/system/media/bootanimation.zip"
  else
    log "No custom bootanimation.zip provided, skipping"
  fi

  if [ -f props/system.prop ]; then
    log "Appending custom properties"
    sudo tee -a "${MOUNT_DIR}/system/build.prop" < props/system.prop >/dev/null
  fi

  log "Unmounting image"
  sudo umount "${MOUNT_DIR}"

  log "Shrinking filesystem to minimum"
  sudo resize2fs -M "${WORK_DIR}/system.raw.img"
  sudo e2fsck -fy "${WORK_DIR}/system.raw.img"

  log "Converting raw image back to sparse format"
  img2simg "${WORK_DIR}/system.raw.img" "${OUTPUT_DIR}/system-neko.img"

  log "Customization complete: ${OUTPUT_DIR}/system-neko.img"
}

main "$@"
