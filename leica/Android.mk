LOCAL_PATH := $(call my-dir)

ifeq ($(wildcard $(LOCAL_PATH)/system/priv-app/MiuiCamera/MiuiCamera.apk),)
$(shell cat $(LOCAL_PATH)/system/priv-app/MiuiCamera/MiuiCamera.apk.part_* > $(LOCAL_PATH)/system/priv-app/MiuiCamera/MiuiCamera.apk)
endif

include $(CLEAR_VARS)
LOCAL_MODULE := MiuiCamera
LOCAL_MODULE_TAGS := optional
LOCAL_SRC_FILES := system/priv-app/MiuiCamera/MiuiCamera.apk
LOCAL_MODULE_CLASS := APPS
LOCAL_MODULE_SUFFIX := $(COMMON_ANDROID_PACKAGE_SUFFIX)
LOCAL_CERTIFICATE := PRESIGNED
LOCAL_PRIVILEGED_MODULE := true
LOCAL_DEX_PREOPT := false
LOCAL_OVERRIDES_PACKAGES := Snap Camera2

MIUICAMERA_DIR := $(TARGET_OUT)/priv-app/MiuiCamera
LOCAL_POST_INSTALL_CMD := \
	mkdir -p $(MIUICAMERA_DIR)/lib/arm64 && \
	cp -f $(LOCAL_PATH)/system/priv-app/MiuiCamera/lib/arm64/*.so $(MIUICAMERA_DIR)/lib/arm64/

$(LOCAL_INSTALLED_MODULE): PRIVATE_POST_INSTALL_CMD := $(LOCAL_POST_INSTALL_CMD)

include $(BUILD_PREBUILT)

include $(CLEAR_VARS)
LOCAL_MODULE := MiuiExtraPhoto
LOCAL_MODULE_TAGS := optional
LOCAL_SRC_FILES := system/priv-app/MiuiExtraPhoto/MiuiExtraPhoto.apk
LOCAL_MODULE_CLASS := APPS
LOCAL_MODULE_SUFFIX := $(COMMON_ANDROID_PACKAGE_SUFFIX)
LOCAL_CERTIFICATE := PRESIGNED
LOCAL_PRIVILEGED_MODULE := true
LOCAL_DEX_PREOPT := false

MIUIEXTRAPHOTO_DIR := $(TARGET_OUT)/priv-app/MiuiExtraPhoto
LOCAL_POST_INSTALL_CMD := \
	mkdir -p $(MIUIEXTRAPHOTO_DIR)/lib/arm64 && \
	cp -f $(LOCAL_PATH)/system/priv-app/MiuiExtraPhoto/lib/arm64/*.so $(MIUIEXTRAPHOTO_DIR)/lib/arm64/

$(LOCAL_INSTALLED_MODULE): PRIVATE_POST_INSTALL_CMD := $(LOCAL_POST_INSTALL_CMD)

include $(BUILD_PREBUILT)
