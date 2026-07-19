# Extra fs_config rules consumed by build/tools/fs_config/fs_config_generator.py
# via TARGET_FS_CONFIG_GEN (set in BoardConfig.mk).
#
# Root cause this exists to fix: the AOSP recovery-ramdisk packaging rule
# (build/make/core/Makefile, android-14.0.0_r67) runs
#   $(MKBOOTFS) -d $(TARGET_OUT) $(TARGET_RECOVERY_ROOT_OUT) | ...
# and mkbootfs's "-d" flag makes it discard every packed file's real
# on-disk stat() mode entirely, replacing it via fs_config() pattern
# lookup instead (system/core/libcutils/fs_config.cpp). OrangeFox's own
# Fox_Before_Recovery_Image hook does correctly `chmod 0755` everything
# under sbin/ on disk, but that's irrelevant — fs_config() doesn't
# recognize the OrangeFox/TWRP-specific /sbin/* path convention (it's
# not a stock AOSP path like system/bin/*), so every unmatched file
# silently falls through to fs_config's terminal default: 0644 root:root.
# Confirmed via `cpio -tv` on a built boot.img's ramdisk: every /sbin
# binary (bash, magiskboot, zip, foxstart.sh — OrangeFox's own launcher)
# came out -rw-r--r--, which is why the recovery UI never started and
# the device fell back to the stock "No command" screen.
[sbin/*]
mode: 0755
user: AID_ROOT
group: AID_ROOT
caps: 0
