# NekoOS GSI Customizer

NekoOS 现在以官方 AOSP GSI 为基础，通过脚本化流程注入 Pixel 风格 overlay、属性与自定义资源，避免从源代码完整编译。

## 目录结构

- `scripts/customize_gsi.sh`：核心脚本，下载/解包/挂载官方 system.img 并套入 NekoOS 定制。
- `overlays/`：Runtime Resource Overlay 资源，覆盖 SystemUI 配色等内容。
- `assets/bootanimation/`：自定义开机动画目录，放入 `bootanimation.zip` 即可被脚本打包进系统。
- `props/system.prop`：附加到 `build.prop` 的属性片段，可声明版本号、开关功能。

## 使用方法

1. 修改 `scripts/customize_gsi.sh` 顶部的 `GSI_URL`，指向实际的 Android 16 arm64-ab 官方 GSI 压缩包。
2. 将想要替换的资源放入对应目录，例如：
   - `overlays/` 内新增更多 overlay 目录。
   - 将真正的 `bootanimation.zip` 放在 `assets/bootanimation/`。
   - 在 `props/system.prop` 追加属性行。
3. 在 Ubuntu 环境执行：

   ```bash
   sudo apt-get install -y android-sdk-libsparse-utils e2fsprogs unzip curl
   chmod +x scripts/customize_gsi.sh
   sudo scripts/customize_gsi.sh
   ```

   脚本会输出 `output/system-neko.img`，可用于 DSU Sideloader 或 fastbootd 刷写。

> # TODO: add more overlays or prebuilt assets here

## GitHub Actions

`.github/workflows/build.yml` 提供示例工作流：

- 检查并释放磁盘空间。
- 安装 `repo` 以备后续扩展（如需要同步其它仓库）。
- 下载指定 GSI → 运行 `scripts/customize_gsi.sh` → 上传生成的 `system-neko.img`。

默认工作流仍需你设置 `GSI_URL`（可通过 repository secret 或直接修改脚本），并确保 runner 具备足够磁盘空间。
