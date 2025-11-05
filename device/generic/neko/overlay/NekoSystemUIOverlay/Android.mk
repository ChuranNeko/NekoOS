# 构建 NekoSystemUIOverlay 静态 overlay 包。
LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_PACKAGE_NAME := NekoSystemUIOverlay       # overlay 包名
LOCAL_RESOURCE_DIR := $(LOCAL_PATH)/res         # 资源根目录
LOCAL_MANIFEST_FILE := AndroidManifest.xml     # 指定 manifest
LOCAL_SDK_VERSION := current                   # 使用当前 SDK
LOCAL_CERTIFICATE := platform                  # 使用 platform 签名
LOCAL_PRODUCT_MODULE := true                   # 安装到 product 分区

# TODO: add more overlays or prebuilt apps here

include $(BUILD_PACKAGE)
