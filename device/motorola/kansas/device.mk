#
# Common device configuration for kansas (Moto G 2025).
# This file is inherited by twrp_kansas.mk. Keep it free of
# product-identity strings (name/brand/fingerprint) — those live
# in twrp_kansas.mk so this file stays reusable.
#

LOCAL_PATH := device/motorola/kansas

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/recovery/root/etc/twrp.fstab:$(TARGET_COPY_OUT_RECOVERY)/root/etc/twrp.fstab \
    $(LOCAL_PATH)/recovery/root/init.recovery.kansas.rc:$(TARGET_COPY_OUT_RECOVERY)/root/init.recovery.kansas.rc

# Recovery-side init/ueventd rc — only needed if the stock boot ramdisk
# doesn't already carry an init.recovery.<board>.rc; delete the
# PRODUCT_COPY_FILES line above if it does (check the extracted boot
# ramdisk with `abootimg -x boot.img` first).

PRODUCT_PACKAGES += \
    libtwrpfsck \
    twrp \
    parted

# --- Networking blobs frequently required for TWRP MTP/ADB/backup to work ---
PRODUCT_PACKAGES += \
    libion

# Left disabled: first CI build failed with "vendor/motorola/kansas/
# kansas-vendor.mk does not exist" — no proprietary-blobs vendor tree
# has been pulled for this device (e.g. via TheMuppets-style OTA
# extraction), and a recovery-only build doesn't need one since
# OrangeFox statically links almost everything it needs. Uncomment
# only after actually creating vendor/motorola/kansas/kansas-vendor.mk.
# $(call inherit-product, vendor/motorola/kansas/kansas-vendor.mk)

# Fourth CI failure: "build/make/target/product/embedded.mk does not
# exist" — this is a trimmed "minimal manifest" build/make fork, not
# full AOSP, and doesn't carry most of target/product/*.mk. Verified
# against a real working same-chipset (mt6835) OrangeFox device tree
# (Sairb1/realme11-mt6835-orangefox-device-tree): it inherits only
# these two, both confirmed present in this fork's target/product/.
ENABLE_VIRTUAL_AB := true
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)
