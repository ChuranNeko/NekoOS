# NekoOS

NekoOS 是基于 Android 16 (android-16.0.0_r1) 的 arm64-ab GSI 项目模板，目标风格接近 Pixel SystemUI 与 Material You。

## 快速开始

1. 运行 `./build.sh` 在本地同步并编译 `systemimage`。
2. 如需 CI，请参考 `.github/workflows/build.yml`。
3. 将生成的 `out/target/product/arm64_ab/system.img` 通过 DSU Sideloader 测试。
4. 构建脚本会克隆 PixelExperience 的 `vendor_pixel-framework` 仓库作为 Pixel 风格参考资源，可在 `vendor/pixel-framework/` 中按需裁剪。

> # TODO: add more overlays or prebuilt apps here

欢迎根据实际需求扩展 overlay、应用或属性配置。
