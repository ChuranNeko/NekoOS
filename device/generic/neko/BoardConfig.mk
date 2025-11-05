# GSI 目标的一些基础板级设置。
TARGET_ARCH := arm64                # 指定 64 位架构
TARGET_ARCH_VARIANT := armv8-a      # 架构变种
TARGET_CPU_VARIANT := generic       # CPU 通用设置
TARGET_USES_64_BIT_BINDER := true   # 启用 64 位 binder 支持

# TODO: add more overlays or prebuilt apps here
