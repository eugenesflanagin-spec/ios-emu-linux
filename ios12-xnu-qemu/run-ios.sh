#!/usr/bin/env bash
# Boot iOS 12.1 (iPhone 6s Plus, n66) on the Aleph Security xnu-qemu-arm64 fork.
# SCREEN MODE (2026-10-24): a QEMU window shows the iOS text framebuffer (verbose boot,
# then the root bash-4.4# shell). Type in THIS terminal - it is the keyboard (serial input);
# the output appears in the QEMU window. ~60-75 s to the prompt (press Enter once).
# Also: SSH from another terminal once booted:  ./ssh-ios.sh   (root / alpine, port 2222)
# Old serial-only mode (everything in this terminal, no window): ./run-ios-console.sh
# Inside the shell:
#   export PATH=$PATH:/iosbinpack64/usr/bin:/iosbinpack64/bin:/iosbinpack64/usr/sbin:/iosbinpack64/sbin
# Quit QEMU with Ctrl-a x here (Ctrl-a c = QEMU monitor), or close the window.
set -e
WORK="$(cd "$(dirname "$0")" && pwd)"
BUILD="$WORK/build"
QEMU="$WORK/qemu/aarch64-softmmu/qemu-system-aarch64"   # branch ios-screen (32bpp ramfb + Linux tunnel fixes)
cd "$BUILD"
# hfs.sec is mounted r/w by iOS and never cleanly unmounted when QEMU is killed: repair it.
if command -v fsck.hfsplus >/dev/null 2>&1; then
    echo "[run-ios] repairing hfs.sec ..."
    fsck.hfsplus -fy "$BUILD/hfs.sec" >/dev/null 2>&1 || true
fi
echo "[run-ios] starting QEMU - watch the QEMU window; type here (this terminal is the keyboard)."
echo "[run-ios] when the window shows the boot has settled (~70 s), press Enter for the bash-4.4# prompt."
exec "$QEMU" \
  -M iPhone6splus-n66-s8000,kernel-filename=kernelcache.release.n66.out,dtb-filename=DeviceTree.n66ap.im4p.out,driver-filename=aleph_bdev_drv.bin,qc-file-0-filename=hfs.main,qc-file-1-filename=hfs.sec,kern-cmd-args="debug=0x8 kextlog=0xfff cpus=1 rd=disk0 serial=2",xnu-ramfb=on \
  -cpu max -m 6G -display gtk -name "iOS 12.1 - iPhone 6s Plus (QEMU)" -serial mon:stdio
