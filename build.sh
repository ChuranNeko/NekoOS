#!/usr/bin/env bash
set -euo pipefail

# 本地构建脚本：同步 AOSP、设置环境、编译 systemimage。
# 可根据需要添加 ccache、mirror 等进一步配置。

SOURCE_DIR="${PWD}/source"       # 指定源码目录，默认在仓库下方
BRANCH="android-16.0.0_r1"       # 指定 AOSP 分支
LUNCH_CHOICE="aosp_arm64_ab-userdebug"  # 指定 lunch 目标
JOBS="$(nproc)"                  # 并行编译线程数

mkdir -p "${SOURCE_DIR}"
cd "${SOURCE_DIR}"

if [ ! -d ".repo" ]; then
  echo "[INFO] 初始化 AOSP repo..."
  repo init -u https://android.googlesource.com/platform/manifest -b "${BRANCH}"
fi

echo "[INFO] 同步源码，这可能需要较长时间..."
repo sync -c --force-sync --no-clone-bundle --no-tags

# TODO: add more overlays or prebuilt apps here

echo "[INFO] 复制 NekoOS 设备/应用/overlay 内容到工作区..."
rsync -a --delete ../device/ device/
rsync -a --delete ../vendor/ vendor/
rsync -a --delete ../packages/ packages/
rsync -a --delete ../system/ system/

# 同步 PixelExperience vendor_pixel-framework 资源，提供 Pixel 风格 SystemUI。
PIXEL_FRAMEWORK_DIR="vendor/pixel-framework"
if [ ! -d "${PIXEL_FRAMEWORK_DIR}/.git" ]; then
  echo "[INFO] 克隆 PixelExperience/vendor_pixel-framework 仓库..."
  git clone https://github.com/PixelExperience/vendor_pixel-framework.git "${PIXEL_FRAMEWORK_DIR}" || true
else
  echo "[INFO] 更新已存在的 PixelExperience/vendor_pixel-framework 仓库..."
  git -C "${PIXEL_FRAMEWORK_DIR}" pull --ff-only || true
fi

source build/envsetup.sh
lunch "${LUNCH_CHOICE}"

echo "[INFO] 开始编译 systemimage..."
m -j"${JOBS}" systemimage

echo "[INFO] 编译完成，输出位于 out/target/product/arm64_ab/system.img"
