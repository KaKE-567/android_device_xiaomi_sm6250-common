#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

LEICA_PATH := device/xiaomi/sm6250-common/leica

PRODUCT_PACKAGES += \
    MiuiCamera \
    MiuiExtraPhoto

# Permissions and config
PRODUCT_COPY_FILES += \
    $(LEICA_PATH)/system/etc/permissions/android.hardware.camera.flash-autofocus.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/permissions/android.hardware.camera.flash-autofocus.xml \
    $(LEICA_PATH)/system/etc/permissions/android.hardware.camera.front.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/permissions/android.hardware.camera.front.xml \
    $(LEICA_PATH)/system/etc/permissions/android.hardware.camera.full.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/permissions/android.hardware.camera.full.xml \
    $(LEICA_PATH)/system/etc/permissions/android.hardware.camera.raw.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/permissions/android.hardware.camera.raw.xml \
    $(LEICA_PATH)/system/etc/permissions/privapp-permissions-miuicamera.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/permissions/privapp-permissions-miuicamera.xml \
    $(LEICA_PATH)/system/etc/sysconfig/miuicamera-hiddenapi-package-whitelist.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/sysconfig/miuicamera-hiddenapi-package-whitelist.xml \
    $(LEICA_PATH)/vendor/etc/camera/sceneDetection.xml:$(TARGET_COPY_OUT_VENDOR)/etc/camera/sceneDetection.xml \
    $(LEICA_PATH)/system/priv-app/MiuiCamera/lib/arm64/libc++_shared.so:$(TARGET_COPY_OUT_SYSTEM)/lib64/libc++_shared.so \
    $(LEICA_PATH)/system/priv-app/MiuiCamera/lib/arm64/libcamera_algoup_jni.xiaomi.so:$(TARGET_COPY_OUT_SYSTEM)/lib64/libcamera_algoup_jni.xiaomi.so

# Camera properties
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    persist.vendor.camera.enableAdvanceFeatures=0x7E7 \
    persist.vendor.camera.multicam=TRUE \
    persist.vendor.camera.multicam.fpsmatch=TRUE \
    persist.vendor.camera.multicam.framesync=1 \
    persist.vendor.camera.multicam.hwsync=TRUE \
    persist.vendor.camera.picturesize.limit.enable=false \
    persist.vendor.camera.privapp.list=com.android.camera \
    persist.vendor.camera.remosaic=1 \
    vendor.camera.sensor.hdr.remosaic=1 \
    persist.camera.mialgo.remosaic=1 \
    persist.camera.xiaomi.algoup=1 \
    persist.sys.miui.sdk.dbg=1 \
    ro.miui.notch=1 \
    ro.miui.custom.device=curtana \
    vendor.camera.aux.packagelist=org.codeaurora.snapcam,com.android.camera2,com.android.camera,com.miui.camera \
    ro.com.google.lens.oem_camera_package=com.android.camera

PRODUCT_VENDOR_PROPERTIES += \
    persist.vendor.camera.enableAdvanceFeatures=0x7E7 \
    persist.vendor.camera.multicam=TRUE \
    persist.vendor.camera.multicam.fpsmatch=TRUE \
    persist.vendor.camera.multicam.framesync=1 \
    persist.vendor.camera.multicam.hwsync=TRUE \
    persist.vendor.camera.picturesize.limit.enable=false \
    persist.vendor.camera.privapp.list=com.android.camera \
    persist.vendor.camera.remosaic=1 \
    vendor.camera.sensor.hdr.remosaic=1 \
    persist.camera.mialgo.remosaic=1 \
    persist.camera.xiaomi.algoup=1 \
    vendor.camera.aux.packagelist=org.codeaurora.snapcam,com.android.camera2,com.android.camera,com.miui.camera
