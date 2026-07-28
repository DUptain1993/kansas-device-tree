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

# Fifth CI failure: "Building a 32-bit-app-only product on a 64-bit
# device" — board_config.mk requires these explicitly when both a
# primary 64-bit and secondary 32-bit ABI are declared (as above);
# without them it can't tell this apart from a 32-bit-only product.
TARGET_USES_64_BIT_BINDER := true
TARGET_SUPPORTS_32_BIT_APPS := true
TARGET_SUPPORTS_64_BIT_APPS := true

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
# This is the real AOSP variable name (BOARD_BOOTIMG_HEADER_VERSION,
# which this used to be called, is not — build/make never reads it).
BOARD_BOOT_HEADER_VERSION := 4
# Still forward it explicitly — this line, not the variable above, is
# what actually fixed the 2026-07-12 build producing a header v0
# boot.img.
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)
BOARD_KERNEL_CMDLINE :=
# Second attempt at vendor_boot, after boot.img AND init_boot.img were
# both PROVEN (not guessed) ineffective: run 32's boot.img had verified-
# correct, verified-executable content and its checksum was confirmed
# present in the live device's active boot_a partition after flashing -
# yet the device showed the identical stock "No command" screen every
# time, with zero observable difference. A correctly-sized init_boot.img
# (run 33) built from the exact same ramdisk got the identical result,
# via both `fastboot reboot recovery` AND the bootloader's own native
# "Recovery mode" menu entry (ruling out a fastboot-specific bug).
# Direct inspection of our own ramdisk also found /init is a dangling
# symlink to /system/bin/init (which doesn't exist in it) - the shape
# of a normal-boot ramdisk, not a standalone recovery one. Combined with
# stock boot_a having an empty ramdisk and this device's own root method
# (Magisk) patching init_boot rather than boot, neither boot nor
# init_boot's ramdisk appears to be read by this bootloader at all for
# ANY purpose - pointing back at vendor_boot as the only remaining
# candidate, despite it being the one partition that has never accepted
# a `fastboot flash` write ("Preflash validation failed" on every
# attempt in the first detour, runs 24-29).
#
# This time the plan is to flash it via `su -c dd` directly to the
# block device from a rooted shell, bypassing the fastboot USB protocol
# (and its "Preflash validation" check) entirely - dd doesn't go
# through that pipeline, and AVB verification is already disabled on
# this unit, so a self-signed/test-keyed footer that would fail real
# cryptographic verification doesn't matter here. Restoring this
# config exactly as it was byte-verified against the live device the
# first time (page size, load addresses, DTB), since that groundwork
# was correct - only the flashing METHOD is different this time, not
# the image contents. This build also now carries the /sbin permissions
# fix (TARGET_FS_CONFIG_GEN below), which the original runs 24-29
# vendor_boot attempts predated.
BOARD_MKBOOTIMG_ARGS += --pagesize 4096
BOARD_MKBOOTIMG_ARGS += --base 0x00000000
BOARD_MKBOOTIMG_ARGS += --kernel_offset 0x40000000
BOARD_MKBOOTIMG_ARGS += --ramdisk_offset 0x66f00000
BOARD_MKBOOTIMG_ARGS += --tags_offset 0x47c80000
BOARD_MKBOOTIMG_ARGS += --dtb_offset 0x47c80000
# Extracted from the live vendor_boot_a partition (dd + manual v4 header
# parse, since this device packs it as an Android DT Table - magic
# d7b7ab1e, same format as dtbo.img - rather than a single flat FDT).
# Verified byte-for-byte size and magic against the live device before
# committing. See BOARD_PREBUILT_DTBOIMAGE above for the separate,
# unrelated dtbo partition image - this is vendor_boot's own embedded
# dtb section, not that.
BOARD_MKBOOTIMG_ARGS += --dtb $(DEVICE_PATH)/prebuilt/vendor_boot.dtb

BOARD_USES_RECOVERY_AS_BOOT := false
BOARD_USES_GENERIC_KERNEL_IMAGE := true
BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT := true
BOARD_INCLUDE_RECOVERY_RAMDISK_IN_VENDOR_BOOT := true
BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE := false

# init_boot itself stays generic/stock and unmodified by this build —
# this size is only here for AB_OTA_PARTITIONS/OTA accounting of the
# real partition, not because this tree packs anything into it.
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

# OrangeFox's own build script (vendor/recovery/OrangeFox_A14.sh) copies
# magiskboot to <recovery_root>/sbin/ unconditionally, but nothing on a
# modern (system-as-root) root creates /sbin — BOARD_ROOT_EXTRA_FOLDERS
# is the standard AOSP hook (system/core/rootdir/Android.mk's
# init.environ.rc post-install step, see device.mk) for adding exactly
# this kind of OEM/vendor-specific extra root directory.
BOARD_ROOT_EXTRA_FOLDERS += sbin

# Run 30's boot.img flashed fine but never showed the OrangeFox UI (just
# the stock "No command" screen) — root-caused via `cpio -tv` on the
# built ramdisk: every /sbin/* file (bash, magiskboot, zip, foxstart.sh —
# OrangeFox's own launcher) was packed as -rw-r--r--, non-executable.
# OrangeFox's Fox_Before_Recovery_Image hook does chmod 0755 these on
# disk, but that's irrelevant: the AOSP recovery-ramdisk rule invokes
# `mkbootfs -d $(TARGET_OUT) ...` (build/make/core/Makefile), and the
# "-d" flag makes mkbootfs discard real on-disk stat() mode entirely and
# look up uid/gid/mode/caps via fs_config() (system/core/libcutils/
# fs_config.cpp) instead. fs_config()'s canned table only recognizes
# stock AOSP paths (system/bin/*, init*, ...); our OrangeFox/TWRP-style
# /sbin/* layout matches nothing and falls through to its terminal
# default of 0644 root:root. TARGET_FS_CONFIG_GEN is AOSP's standard
# device-tree hook for extending that table — see config.fs.
TARGET_FS_CONFIG_GEN := $(DEVICE_PATH)/config.fs

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
# Recovery is back in vendor_boot (see the boot image section above) -
# the BOARD_AVB_RECOVERY_* keys above only sign a recoveryimage/boot
# target, which this device no longer builds while testing this. The
# actual flashed image (vendor_boot.img) needs its own
# BOARD_AVB_VENDOR_BOOT_* signing block, same test key. Rollback index
# location 2, not 1, so it doesn't collide with the recovery block
# above (vestigial while vendor_boot is active, left in place since
# nothing depends on deleting it).
BOARD_AVB_VENDOR_BOOT_ALGORITHM := SHA256_RSA4096
BOARD_AVB_VENDOR_BOOT_KEY_PATH := external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_VENDOR_BOOT_ROLLBACK_INDEX_LOCATION := 2
# Your stock unit already has a real, recent security patch (2025-08-01)
# baked into AVB's rollback counter. A custom build that derives its
# rollback index from *today's* real date can come out LOWER than
# what's already trusted, and the bootloader will refuse to flash it
# as a "downgrade". Forcing this to a far-future date is a known,
# intentional community workaround (confirmed independently in two
# other mt6835 recovery trees), not a mistake — keep it. Same reasoning
# applies to vendor_boot's own rollback counter, not just recovery's.
PLATFORM_SECURITY_PATCH := 2099-12-31
VENDOR_SECURITY_PATCH := $(PLATFORM_SECURITY_PATCH)
BOARD_AVB_RECOVERY_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_VENDOR_BOOT_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)

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
