#!/usr/bin/env bash
set -euo pipefail

# Customization script that patches an official AOSP GSI system image with NekoOS assets.
# Supports both ext4-based (sparse/raw) and EROFS-based images used by newer Android releases.

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

default_gsi_url() {
  case "$1" in
    arm64)
      echo "https://dl.google.com/developers/android/baklava/images/gsi/aosp_arm64-exp-BP41.250916.012.A1-14330953-171efa95.zip"
      ;;
    arm64_gms|gms)
      echo "https://dl.google.com/developers/android/baklava/images/gsi/gsi_gms_arm64-exp-BP41.250916.012.A1-14330953-45857949.zip"
      ;;
    *)
      echo "fatal: unsupported GSI_FLAVOR '${1}'" >&2
      exit 1
      ;;
  esac
}

detect_image_type() {
  local image="$1"
  local description
  description=$(file -b "$image")
  if [[ "$description" == *"Android sparse image"* ]]; then
    echo "sparse"
  elif [[ "$description" == *"ext4 filesystem data"* ]]; then
    echo "ext4"
  elif [[ "$description" == *"EROFS"* ]]; then
    echo "erofs"
  else
    echo "fatal: unsupported system image format: $description" >&2
    exit 1
  fi
}

apply_customizations() {
  local target_root="$1"

  log "Applying overlays"
  sudo mkdir -p "${target_root}/system/product/overlay/NekoSystemUIOverlay"
  sudo cp -r overlays/NekoSystemUIOverlay/. "${target_root}/system/product/overlay/NekoSystemUIOverlay/"

  if [ -f assets/bootanimation/bootanimation.zip ]; then
    log "Installing custom bootanimation"
    sudo mkdir -p "${target_root}/system/media"
    sudo cp assets/bootanimation/bootanimation.zip "${target_root}/system/media/bootanimation.zip"
  else
    log "No custom bootanimation.zip provided, skipping"
  fi

  if [ -f props/system.prop ]; then
    log "Appending custom properties"
    sudo tee -a "${target_root}/system/build.prop" < props/system.prop >/dev/null
  fi
}

customize_ext4_image() {
  local image_type="$1"
  local image_path="$2"

  require_tool simg2img
  require_tool img2simg
  require_tool e2fsck
  require_tool resize2fs

  local raw_image="${WORK_DIR}/system.raw.img"
  if [ "$image_type" = "sparse" ]; then
    log "Converting sparse system image to raw ext4"
    simg2img "$image_path" "$raw_image"
  else
    log "Copying raw ext4 system image"
    cp "$image_path" "$raw_image"
  fi

  log "Running filesystem check"
  sudo e2fsck -fy "$raw_image"

  log "Expanding filesystem to provide customization headroom"
  sudo resize2fs "$raw_image" 6144M

  local mount_dir="${WORK_DIR}/mount"
  mkdir -p "$mount_dir"
  log "Mounting raw image"
  sudo mount -o loop "$raw_image" "$mount_dir"

  apply_customizations "$mount_dir"

  log "Unmounting image"
  sudo umount "$mount_dir"

  log "Shrinking filesystem to minimum"
  sudo resize2fs -M "$raw_image"
  sudo e2fsck -fy "$raw_image"

  mkdir -p "$OUTPUT_DIR"
  log "Converting raw image back to sparse format"
  img2simg "$raw_image" "${OUTPUT_DIR}/system-neko.img"
}

customize_erofs_image() {
  local image_path="$1"

  require_tool erofsfuse
  require_tool fusermount3
  require_tool rsync
  require_tool mkfs.erofs

  local mount_dir="${WORK_DIR}/erofs_mount"
  local rootfs_dir="${WORK_DIR}/rootfs"
  local output_uid="${SUDO_UID:-$(id -u)}"
  local output_gid="${SUDO_GID:-$(id -g)}"

  if [ ! -f "$rootfs_dir/.extracted" ]; then
    mkdir -p "$mount_dir" "$rootfs_dir"
    log "Mounting EROFS image via FUSE"
    sudo erofsfuse "$image_path" "$mount_dir"
    log "Copying filesystem contents for modification"
    sudo rsync -aHAX "$mount_dir/" "$rootfs_dir/"
    sudo touch "$rootfs_dir/.extracted"
    sudo fusermount3 -u "$mount_dir"
  fi

  apply_customizations "$rootfs_dir"

  mkdir -p "$OUTPUT_DIR"
  local temp_img="${OUTPUT_DIR}/system-neko.img.tmp"
  log "Packing modified rootfs as EROFS"
  sudo mkfs.erofs -zlz4hc --mount-point=/system "$temp_img" "$rootfs_dir"
  sudo chown "${output_uid}:${output_gid}" "$temp_img"
  mv "$temp_img" "${OUTPUT_DIR}/system-neko.img"
}

main() {
  if [ -z "${GSI_URL}" ]; then
    GSI_URL="$(default_gsi_url "${GSI_FLAVOR}")"
    log "GSI_URL not provided, defaulting to ${GSI_FLAVOR} build"
  else
    log "Using user supplied GSI_URL"
  fi

  if [ -z "${GSI_ZIP}" ]; then
    strip_query="${GSI_URL%%\?*}"
    GSI_ZIP="$(basename "$strip_query")"
  fi

  require_tool curl
  require_tool unzip
  require_tool file

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

  local full_image="${WORK_DIR}/system.img"
  local image_type
  image_type=$(detect_image_type "$full_image")
  log "Detected system image format: $image_type"

  case "$image_type" in
    sparse|ext4)
      customize_ext4_image "$image_type" "$full_image"
      ;;
    erofs)
      customize_erofs_image "$full_image"
      ;;
  esac

  log "Customization complete: ${OUTPUT_DIR}/system-neko.img"
}

main "$@"
