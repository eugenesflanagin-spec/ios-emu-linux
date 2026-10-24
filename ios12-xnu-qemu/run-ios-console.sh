#!/usr/bin/env bash
# Boot iOS 12.1 (iPhone 6s Plus, n66) on the Aleph Security xnu-qemu-arm64 fork.
# Reaches an interactive root bash shell on the serial console (bash-4.4#).
# Inside the shell, set PATH to use the iosbinpack64 tools:
#   export PATH=$PATH:/iosbinpack64/usr/bin:/iosbinpack64/bin:/iosbinpack64/usr/sbin:/iosbinpack64/sbin
# Quit QEMU with Ctrl-a x  (Ctrl-a c switches to the QEMU monitor).
set -e
# SERIAL-ONLY MODE: no window, kernel log + bash all on this terminal (the original 10-24 setup).
# For the iOS screen in a window use ./run-ios.sh. SSH works in both modes: ./ssh-ios.sh
WORK="$(cd "$(dirname "$0")" && pwd)"
BUILD="$WORK/build"
QEMU="$WORK/qemu/aarch64-softmmu/qemu-system-aarch64"   # pre-screen binary: qemu-system-aarch64.working
cd "$BUILD"
# The secondary disk (hfs.sec) is mounted read-write by iOS and is never cleanly
# unmounted when QEMU is killed, so repair it before each launch (no root needed).
if command -v fsck.hfsplus >/dev/null 2>&1; then
    echo "[run-ios] repairing hfs.sec ..."
    fsck.hfsplus -fy "$BUILD/hfs.sec" >/dev/null 2>&1 || true
fi
echo "[run-ios] starting QEMU - wait ~60-75s for the  bash-4.4#  prompt"
exec "$QEMU" \
  -M iPhone6splus-n66-s8000,kernel-filename=kernelcache.release.n66.out,dtb-filename=DeviceTree.n66ap.im4p.out,driver-filename=aleph_bdev_drv.bin,qc-file-0-filename=hfs.main,qc-file-1-filename=hfs.sec,kern-cmd-args="debug=0x8 kextlog=0xfff cpus=1 rd=disk0 serial=2",xnu-ramfb=off \
  -cpu max -m 6G -display none -serial mon:stdio
