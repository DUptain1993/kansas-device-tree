#
# BoardConfig.mk for kansas (Moto G 2025)
#
# Values below were pulled directly from a live rooted "kansas" unit
# (getprop, `su -c lpdump`, `su -c blockdev --getsize64`, boot.img
# header parsed by hand) rather than guessed. Anything still marked
# TODO could not be read from the running device and needs manual
# confirmation. Re-verify after any OTA — Motorola ships partition
# layout changes across security-patch updates on this platform.
#

DEVICE_PATH := device/motorola/kansas

# ------------------------------------------------------------------
# Architecture
# ------------------------------------------------------------------
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := generic
TARGET_CPU_VARIANT_RUNTIME := generic

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := generic

# Confirmed: getprop ro.board.platform / ro.hardware on-device == mt6835
# (MediaTek Dimensity 6300-class SoC).
TARGET_BOARD_PLATFORM := mt6835

# ------------------------------------------------------------------
# Kernel integration
# ------------------------------------------------------------------
# Running kernel is Linux 5.15.180-android13-8 (`uname -r` on-device),
# which matches MotorolaMobilityLLC/kernel-mtk tag MMI-W1VKS36H.9-12-1
# exactly (Makefile there: VERSION=5 PATCHLEVEL=15 SUBLEVEL=180) — that
# is confirmed to be the correct kernel source for this unit.
#
# Mode A (active): reuse the stock prebuilt kernel. Already extracted
# and committed at device/motorola/kansas/prebuilt/ from a live boot_a
# dump on this exact unit (dd + AOSP's unpack_bootimg.py):
#   - Image.lz4: kernel_size 24996836 bytes, LZ4-legacy compressed
#     (magic 02 21 4c 18) — NOT gzip, despite most TWRP tree examples
#     online assuming Image.gz-dtb. boot_a's ramdisk_size is 0 (no
#     ramdisk in boot at all — it lives in init_boot, see below).
#   - dtbo.img: raw dump of dtbo_a, valid DTBO magic (d7 b7 ab 1e)
#     confirmed, used as-is (it's a flashable image, not something
#     mkbootimg needs to repack).
# To refresh after an OTA: su -c 'dd if=/dev/block/by-name/boot_a
# of=/data/local/tmp/boot_a.img' then unpack_bootimg.py --boot_img
# boot_a.img --out out/, take out/kernel as the new Image.lz4.
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/Image.lz4
BOARD_PREBUILT_DTBOIMAGE := $(DEVICE_PATH)/prebuilt/dtbo.img
BOARD_KERNEL_IMAGE_NAME := Image.lz4

# Mode B (not active): build from kernel-mtk source instead. Only
# switch to this if you have a concrete reason to patch kernel
# behavior — comment out the three Mode A lines above and uncomment
# below. TODO: the kernel-mtk tree is shared across several MTK Moto
# devices and its arch/arm64/configs/ has no "kansas" defconfig; the
# mt6835 platform string points at the k6853v1_64_gki_* family, but
# confirm against /proc/config.gz on-device before trusting that:
#   su -c 'zcat /proc/config.gz > /sdcard/running-config.txt' && adb pull /sdcard/running-config.txt
#
# TARGET_KERNEL_SOURCE := kernel/motorola/kansas
# TARGET_KERNEL_CONFIG := k6853v1_64_gki_defconfig
# TARGET_KERNEL_ARCH := arm64
# TARGET_KERNEL_HEADER_ARCH := arm64
# TARGET_KERNEL_CLANG_COMPILE := true
# TARGET_KERNEL_CROSS_COMPILE_PREFIX := aarch64-linux-gnu-

# ------------------------------------------------------------------
# Boot image / recovery-as-boot
# ------------------------------------------------------------------
# Confirmed by hex-dumping the live boot_a partition: magic ANDROID!,
# header_size=1584 (0x630), header_version=4 → boot_img_hdr_v4.
BOARD_BOOTIMG_HEADER_VERSION := 4
BOARD_KERNEL_CMDLINE :=
# BOARD_KERNEL_BASE / BOARD_KERNEL_PAGESIZE are a v0-v2 boot header
# concept and unused for header v4 — deliberately omitted, do not
# re-add them without a reason.

# by-name has no `recovery`/`recovery_a` entry at all on this unit —
# confirmed BOARD_USES_RECOVERY_AS_BOOT is correct, not a guess.
BOARD_USES_RECOVERY_AS_BOOT := true

# This device has a SEPARATE init_boot_a/init_boot_b partition
# (Android-13-style GKI 2.0 split) and boot_a's ramdisk is empty, so
# the recovery ramdisk must be packed into init_boot, not boot or
# vendor_boot. Do NOT set BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT
# — that flag is for older A/B devices WITHOUT a separate init_boot,
# which this is not.
BOARD_INIT_BOOT_IMAGE_PARTITION_SIZE := 0x00800000

# ------------------------------------------------------------------
# Partitions — all sizes below are exact, read live via
# `su -c blockdev --getsize64 /dev/block/by-name/<part>`.
# ------------------------------------------------------------------
BOARD_BOOTIMAGE_PARTITION_SIZE := 0x04000000
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := 0x04000000
BOARD_DTBOIMG_PARTITION_SIZE := 0x00800000

# Virtual A/B confirmed: `su -c lpdump` reports
# "Header flags: virtual_ab_device". Group is named "main" (main_a /
# main_b), NOT a device-specific name — do not invent one.
AB_OTA_UPDATER := true
AB_OTA_PARTITIONS += boot init_boot vendor_boot dtbo vbmeta vbmeta_system
BOARD_USES_AB_OTA := true
BOARD_SUPER_PARTITION_METADATA_DEVICE := super
BOARD_SUPPORTS_VIRTUAL_AB := true
TARGET_NO_RECOVERY := false

BOARD_SUPER_PARTITION_SIZE := 8355053568
BOARD_SUPER_PARTITION_GROUPS := main
BOARD_MAIN_PARTITION_LIST := product system system_dlkm system_ext vendor vendor_dlkm
BOARD_MAIN_SIZE := 8352956416

BOARD_SUPPRESS_SECURE_ERASE := true
TW_INCLUDE_REPACKTOOLS := true

# ------------------------------------------------------------------
# Filesystem / block devices
# ------------------------------------------------------------------
# fstab.mt6835 on-device declares system/vendor/product/system_ext as
# erofs with an ext4 fallback stanza — build ext4 for the recovery
# side per standard TWRP practice, erofs is read-only stock only.
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true
BOARD_HAS_LARGE_FILESYSTEM := true
BOARD_SYSTEMIMAGE_PARTITION_TYPE := ext4
BOARD_USERDATAIMAGE_PARTITION_TYPE := f2fs
BOARD_FLASH_BLOCK_SIZE := 131072

# ------------------------------------------------------------------
# Crypto — read directly from the live /vendor/etc/fstab.mt6835 data
# line: fileencryption=aes-256-xts:aes-256-cts:v2+inlinecrypt_optimized
# +wrappedkey_v0, metadata_encryption=aes-256-xts:wrappedkey_v0,
# keydirectory=/metadata/vold/metadata_encryption. wrappedkey_v0 means
# key unwrap goes through the Keymint HAL/TEE (Trustonic here — see
# android.hardware.security.keymint-service.trustonic.xml in the
# vendor VINTF manifest); decrypting user data from recovery needs a
# working keymint HAL binder call, which normally only runs in a full
# Android boot. OrangeFox's fox_14.1 source (per OrangeFox/sync's own
# changelog) already carries generic AIDL Weaver / wrappedkey patches
# to system/vold for this class of device — so this isn't something
# to build from scratch — but whether Trustonic's actual HAL/TEE
# binary can be reached from inside the recovery ramdisk on THIS
# device is still unverified and can only be settled by trying a
# build. See OF_SKIP_FBE_DECRYPTION near the end of this file for the
# fallback that doesn't depend on the answer.
TW_INCLUDE_CRYPTO := true
TW_INCLUDE_FBE := true
TW_INCLUDE_FBE_METADATA_DECRYPT := true
TW_CRYPTO_USE_SYSTEM_VOLD := true
BOARD_USES_METADATA_ENCRYPTION := true
# PLATFORM_SECURITY_PATCH / VENDOR_SECURITY_PATCH are set once, near
# the AVB block at the end of this file — do not set them here too,
# VENDOR_SECURITY_PATCH := $(PLATFORM_SECURITY_PATCH) captures the
# value at assignment time (make ":=" semantics), so defining it in
# two places silently keeps the wrong one.

# ------------------------------------------------------------------
# VINTF — deliberately NOT configured here. DEVICE_MANIFEST_FILE /
# PRODUCT_ENFORCE_VINTF_MANIFEST matter when you build and flash your
# OWN /vendor image; this tree reuses the stock, unmodified vendor
# partition, so framework/vendor VINTF matching is whatever Motorola
# already shipped and is untouched by a recovery-only build. Do not
# add those flags back unless this tree grows into a full ROM build
# that replaces /vendor.
# ------------------------------------------------------------------

# ------------------------------------------------------------------
# TWRP / OrangeFox recovery behavior flags
# ------------------------------------------------------------------
TW_THEME := portrait_hdpi
TW_EXTRA_LANGUAGES := true
TW_SCREEN_BLANK_ON_BOOT := true
TW_INPUT_BLACKLIST := "hbtp_vm"
TW_NO_BATT_PERCENT := false
TW_USE_TOOLBOX := true
RECOVERY_SDCARD_ON_DATA := true
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery/root/etc/twrp.fstab
TARGET_RECOVERY_PIXEL_FORMAT := "ABGR_8888"
TARGET_RECOVERY_QCOM_RTC_FIX := false

# No /cache entry exists in this device's by-name table — confirmed,
# do not add TWRP cache-partition flags.
BOARD_HAS_NO_REAL_SDCARD := true
TW_EXCLUDE_APEX := true
TW_INCLUDE_LIBRESETPROP := true

# ------------------------------------------------------------------
# AVB recovery signing — MISSING from the first draft of this tree.
# Without this, the build produces an image the bootloader won't
# accept at all. Self-signed with AOSP's public test key (standard
# practice — you don't have Motorola's private key); requires an
# unlocked bootloader to flash, same as any custom recovery.
# ------------------------------------------------------------------
BOARD_AVB_ENABLE := true
BOARD_AVB_RECOVERY_ALGORITHM := SHA256_RSA4096
BOARD_AVB_RECOVERY_KEY_PATH := external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_RECOVERY_ROLLBACK_INDEX_LOCATION := 1
# Your stock unit already has a real, recent security patch (2025-08-01)
# baked into AVB's rollback counter. A custom build that derives its
# rollback index from *today's* real date can come out LOWER than
# what's already trusted, and the bootloader will refuse to flash it
# as a "downgrade". Forcing this to a far-future date is a known,
# intentional community workaround (confirmed independently in two
# other mt6835 recovery trees), not a mistake — keep it.
PLATFORM_SECURITY_PATCH := 2099-12-31
VENDOR_SECURITY_PATCH := $(PLATFORM_SECURITY_PATCH)
BOARD_AVB_RECOVERY_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)

# ------------------------------------------------------------------
# FBE decrypt in recovery — see the long comment in the crypto section
# above about wrappedkey_v0/Trustonic. OrangeFox has a first-class
# escape hatch for exactly this situation: skip attempting decrypt and
# go straight to a wipe/format-capable recovery. Start with this ON —
# it is the only path guaranteed to produce a working recovery without
# depending on whether Trustonic's Keymint HAL can be reached from the
# recovery ramdisk. Once you have a booting build, try flipping it off
# as an experiment; if decrypt doesn't work you're no worse off.
# ------------------------------------------------------------------
OF_SKIP_FBE_DECRYPTION := 1

-include vendor/motorola/kansas/BoardConfigVendor.mk
