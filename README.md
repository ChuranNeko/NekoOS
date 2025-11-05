# NekoOS GSI Customizer

NekoOS 现以官方 AOSP GSI 为基础，通过脚本流程注入 Pixel 风格 overlay、自定义资源和属性，无需完整编译 AOSP 源码即可生成个性化 system.img。

## 目录结构

- `scripts/customize_gsi.sh`：核心脚本，负责下载、解包、挂载官方 system.img 并套入 NekoOS 定制。
- `overlays/`：Runtime Resource Overlay 示例，可扩展更多 SystemUI/Settings 主题资源。
- `assets/bootanimation/`：放置 `bootanimation.zip` 后脚本会自动拷贝进系统。
- `props/system.prop`：会被追加到 `build.prop`，用于设置版本信息或开关功能。

## 使用方法

1. 根据需求选择 GSI 来源：脚本支持两种默认变体，可通过环境变量控制。
   - `GSI_FLAVOR=arm64`（默认）：纯 AOSP GSI，对应下载地址：
     `https://dl.google.com/developers/android/baklava/images/gsi/aosp_arm64-exp-BP41.250916.012.A1-14330953-171efa95.zip`
   - `GSI_FLAVOR=arm64_gms`：内置 Google Mobile Services 的变体，对应下载地址：
     `https://dl.google.com/developers/android/baklava/images/gsi/gsi_gms_arm64-exp-BP41.250916.012.A1-14330953-45857949.zip`
   - 若需要其他镜像，可设置 `GSI_URL` 指向自定义链接，并可选 `GSI_ZIP` 指定保存文件名。
2. 将想要替换的资源放到对应目录，例如：
   - 在 `overlays/` 下新增更多 overlay 模块。
   - 把正式的 `bootanimation.zip` 放入 `assets/bootanimation/`。
   - 在 `props/system.prop` 追加属性行。
3. 在 Ubuntu 环境执行：

   ```bash
   sudo apt-get install -y android-sdk-libsparse-utils e2fsprogs unzip curl
   chmod +x scripts/customize_gsi.sh
   sudo GSI_FLAVOR=arm64 ./scripts/customize_gsi.sh   # 或 arm64_gms
   ```

   脚本会在 `output/system-neko.img` 生成稀疏镜像，可用于 DSU Sideloader 或 fastbootd 刷写。

> # TODO: add more overlays or prebuilt assets here

## GitHub Actions

`.github/workflows/build.yml` 提供示例工作流：

- 第一步检查/释放磁盘空间，确保下载与挂载镜像有足够空间。
- 自动安装 `android-sdk-libsparse-utils`、`e2fsprogs` 等依赖。
- 通过矩阵依次构建 `arm64` 与 `arm64_gms` 两种口味，分别输出在 `output/<flavor>/system-neko.img` 并作为独立 artifact 上传。

如需改用自定义镜像，可在仓库 Secrets/Variables 中注入 `GSI_URL` 或修改 `GSI_FLAVOR`，即可在 CI 中生成不同风味的 NekoOS GSI。
