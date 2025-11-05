# NekoOS 产品定义文件，用于 lunch 入口。
LOCAL_PATH := $(call my-dir)

PRODUCT_NAME := neko_arm64_ab        # 产品名
PRODUCT_DEVICE := neko_arm64_ab      # 设备 ID
PRODUCT_BRAND := Neko                # 品牌信息
PRODUCT_MANUFACTURER := NekoLabs     # 制造商信息
PRODUCT_MODEL := NekoOS GSI          # 型号名称

PRODUCT_PROPERTY_OVERRIDES += \
    ro.build.description=NekoOS-userdebug \
    ro.build.product=neko_arm64_ab

# TODO: add more overlays or prebuilt apps here

$(call inherit-product, $(SRC_TARGET_DIR)/product/generic_system.mk)
$(call inherit-product, $(LOCAL_PATH)/device.mk)
