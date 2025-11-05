# 注册 NekoOS 产品定义，使 lunch 可以识别。
LOCAL_DIR := $(call my-dir)

PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/neko.mk

COMMON_LUNCH_CHOICES := \
    neko_arm64_ab-userdebug
