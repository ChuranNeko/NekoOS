# 核心产品特性定义，扩展通用 GSI 功能。
PRODUCT_PACKAGES += \
    NekoSettings \
    NekoSystemUIOverlay \
    PixelThemesOverlay

PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    ro.systemui.google_style=1       # 自定义属性：启用 Pixel 风格 SystemUI

# TODO: add more overlays or prebuilt apps here
