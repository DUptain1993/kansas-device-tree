# kansas OrangeFox device tree notes

## Testing a new recovery build before daily use

This device tree builds recovery into `init_boot.img` (not `recovery.img`), so there is no separate packing step.

1. Build and grab `out/target/product/kansas/init_boot.img` from your build tree (or download the CI artifact output).
2. Reboot to bootloader and check the current slot:
   - `fastboot getvar current-slot`
3. Flash the inactive slot's `init_boot`:
   - If current slot is `a`: `fastboot flash init_boot_b init_boot.img`
   - If current slot is `b`: `fastboot flash init_boot_a init_boot.img`
4. Switch to that test slot:
   - `fastboot set_active b` (if you flashed `init_boot_b`)
   - `fastboot set_active a` (if you flashed `init_boot_a`)
5. Boot straight to recovery and test.
6. If recovery fails, return to bootloader and switch back to your original slot:
   - `fastboot set_active <original-slot>`

Optional: you can try `fastboot boot init_boot.img` for temporary testing, but split-`init_boot` devices often do not support this reliably; inactive-slot flashing is the safe path.
