#
# Product definition for the "kansas" recovery build.
# Kept separate from device.mk so device.mk can be inherited by both
# a recovery-only product (this file) and, later, a full ROM product
# if you ever extend this tree beyond recovery.
#

$(call inherit-product, vendor/recovery/config/common.mk)
$(call inherit-product, device/motorola/kansas/device.mk)

PRODUCT_NAME := twrp_kansas
PRODUCT_DEVICE := kansas
PRODUCT_BRAND := motorola
PRODUCT_MODEL := Moto G 2025
PRODUCT_MANUFACTURER := motorola

# Pulled live via `getprop ro.build.fingerprint` on-device.
# Note: ro.vendor.build.fingerprint on this unit reports a DIFFERENT,
# older-looking value (.../kansas:13/W1VK36H.9-12/...) — that's
# Motorola's vendor-partition freeze scheme (vendor blobs versioned
# separately from system), not a mismatch to "fix". Use the system
# fingerprint below.
PRODUCT_BUILD_PROP_OVERRIDES += \
    BUILD_FINGERPRINT="motorola/kansas_g_sys/kansas:16/W1VK36H.9-12/c28420-ee623c6:user/release-keys"
