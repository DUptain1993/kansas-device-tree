#
# Common device configuration for kansas (Moto G 2025).
# This file is inherited by twrp_kansas.mk. Keep it free of
# product-identity strings (name/brand/fingerprint) — those live
# in twrp_kansas.mk so this file stays reusable.
#

LOCAL_PATH := device/motorola/kansas

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/recovery/root/init.recovery.kansas.rc:$(TARGET_COPY_OUT_RECOVERY)/root/init.recovery.kansas.rc

# Recovery-side init/ueventd rc — only needed if the stock boot ramdisk
# doesn't already carry an init.recovery.<board>.rc; delete the
# PRODUCT_COPY_FILES line above if it does (check the extracted boot
# ramdisk with `abootimg -x boot.img` first).
#
# Run 19 dropped the twrp.fstab copy that used to live here
# ($(LOCAL_PATH)/recovery/root/etc/twrp.fstab:$(TARGET_COPY_OUT_RECOVERY)/root/etc/twrp.fstab):
# it's redundant with — and now that root/ is actually populated
# (init.environ.rc above), directly conflicts with — the standard AOSP
# recovery-packaging recipe, which already copies this exact file
# (BoardConfig.mk's TARGET_RECOVERY_FSTAB points at the same path) to
# recovery/root/system/etc/recovery.fstab on its own. Pre-placing a real
# directory at recovery/root/etc/ collided with root/etc being a symlink
# to /system/etc (created by init.environ.rc's post-install step):
# "could not make way for new symlink: root/etc / cannot delete
# non-empty directory: root/etc".

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

# Run 17 tried inheriting generic_ramdisk.mk for its init_first_stage
# package, on the theory that would populate $(TARGET_ROOT_OUT)
# ("root") — wrong: system/core/init/Android.bp forces
# init_first_stage's `installable` to false specifically when
# BOARD_USES_RECOVERY_AS_BOOT is true (comment there: "Do not install
# init_first_stage even with mma if we're system-as-root. Otherwise,
# it will overwrite the symlink."), which this device sets. Confirmed
# empirically: total ninja steps grew (snapuserd_ramdisk etc. landed
# under recovery/root/first_stage_ramdisk/, a different output path)
# but out/target/product/kansas/root still never got created — same
# rsync failure, unchanged.
#
# Run 18 tried a bare "nonempty" stub file in root/ (mirroring AOSP's
# own ramdisk_stub.mk idiom for TARGET_COPY_OUT_VENDOR_RAMDISK) just to
# get the rsync source directory to exist. That got past the rsync,
# but OrangeFox's own build script (vendor/recovery/OrangeFox_A14.sh)
# then failed on the copied-over root needing real structure it didn't
# have: "cp: cannot create regular file '.../root//sbin/magiskboot':
# No such file or directory" and "touch: '.../root/linkerconfig/
# ld.config.txt': No such file or directory" — a stub file alone
# doesn't create the directories OrangeFox and the AOSP recipe itself
# (which touches linkerconfig/ld.config.txt as a placeholder) expect.
#
# Run 19: the real, unconditional (no BOARD_USES_RECOVERY_AS_BOOT
# gating, unlike init_first_stage) AOSP mechanism for this is the
# "init.environ.rc" module (system/core/rootdir/Android.mk) — its
# LOCAL_MODULE_PATH is $(TARGET_ROOT_OUT), and its LOCAL_POST_INSTALL_CMD
# is exactly what mkdir -p's the standard root skeleton (dev, proc,
# sys, linkerconfig, tmp, the bin/etc symlinks, etc. — including
# BOARD_ROOT_EXTRA_FOLDERS, see BoardConfig.mk for the "sbin" OrangeFox
# needs) on every real device. It's normally pulled in by base_system.mk,
# which this recovery-only tree doesn't inherit — add it directly.
PRODUCT_PACKAGES += \
    init.environ.rc

# Run 31's boot.img still packed every /sbin/* file (OrangeFox's own
# launcher foxstart.sh, bash, magiskboot, zip, ...) as non-executable
# (0644) despite BoardConfig.mk's TARGET_FS_CONFIG_GEN := config.fs
# (with a [sbin/*] mode:0755 rule) already being in place. Root-caused:
# TARGET_FS_CONFIG_GEN doesn't compile a table directly into libcutils —
# it only supplies the *input* to the fs_config_files_system /
# fs_config_dirs_system build modules (build/make/tools/fs_config/
# Android.mk), which generate $(TARGET_OUT)/etc/fs_config_files. That's
# the file mkbootfs's `-d $(TARGET_OUT)` flag actually opens at runtime
# (system/core/libcutils/fs_config.cpp's fs_config_open()) before
# falling back to its hardcoded (no-sbin-entry, 0644-default) table.
# Those two modules are normally pulled in by base_system.mk, which —
# like init.environ.rc above — this recovery-only tree doesn't inherit,
# so the module was simply never built, the file never existed, and
# config.fs's rule was silently never consulted. Add them directly, same
# pattern as init.environ.rc.
PRODUCT_PACKAGES += \
    fs_config_files_system \
    fs_config_dirs_system
