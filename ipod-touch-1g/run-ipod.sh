#!/bin/bash
# iPod touch 1G (N45AP, iPhoneOS 1.0) on devos50's qemu-ios.
# usage: run-ipod.sh [--headless] [--keep-autolock]
#   --headless       no window (-display none); drive it via the QMP socket
#   --keep-autolock  skip the automatic "Auto-Lock -> Never" taps after boot
# Keys in the window: H = Home button, P = Power button (a SHORT P press puts
# the device to sleep and it never wakes - upstream issue #19; hold P ~5 s for
# "slide to power off" instead). The mouse is the touchscreen.
set -u
W="$(cd "$(dirname "$0")" && pwd)"
QEMU=$W/src-1g/build/qemu-system-arm
F=$W/files/n45ap
INPUT="python3 -I $W/tools/ipod-input.py"
DISPLAY_OPT="-display sdl"; FIX_AUTOLOCK=1
for a in "$@"; do
  case $a in
    --headless) DISPLAY_OPT="-display none" ;;
    --keep-autolock) FIX_AUTOLOCK=0 ;;
    -h|--help) sed -n 2,9p "$0"; exit 0 ;;
    *) echo "unknown option $a" >&2; exit 2 ;;
  esac
done

# SDL here is sdl2-compat on SDL3; its X11 backend hangs forever in
# SDL_CreateWindow (XIfEvent) with this machine, so use native Wayland.
if [ -n "${WAYLAND_DISPLAY:-}" ] && [ -z "${SDL_VIDEODRIVER:-}" ]; then
  export SDL_VIDEODRIVER=wayland
fi

RUN=/dev/shm/ipod-touch-1g-$$
LOG=$W/logs/serial-last.log
QMP=$RUN/qmp.sock
mkdir -p "$RUN" "$W/logs"
QPID=""
cleanup() {
  if [ -n "$QPID" ] && kill "$QPID" 2>/dev/null; then
    sleep 1; kill -9 "$QPID" 2>/dev/null
  fi
  [ -n "${HPID:-}" ] && kill "$HPID" 2>/dev/null
  rm -rf "$RUN"
}
trap cleanup EXIT INT TERM

# The NAND is ~133k small page files. On the ntfs3 HDD the emulator stalls on
# disk seeks, so every run unpacks a fresh copy into RAM (/dev/shm, ~520 MB).
# The emulator never persists NAND writes anyway (it writes *_new.page files
# and never reads them back), so each boot starts from the pristine image.
unzip -q "$F/nand_n45ap.zip" 'nand/*' -d "$RUN" || { echo "unzip failed" >&2; exit 1; }
cp "$F/nor_n45ap.bin" "$RUN/nor.bin"
: > "$LOG"

"$QEMU" -M "iPod-Touch,bootrom=$F/bootrom_s5l8900,iboot=$F/iboot_204_n45ap.bin,nand=$RUN/nand" \
  -cpu max -m 1G $DISPLAY_OPT -name "iPod touch 1G (iPhoneOS 1.0)" \
  -serial "file:$LOG" -qmp "unix:$QMP,server,nowait" \
  -monitor "unix:$RUN/monitor.sock,server,nowait" \
  -drive "if=pflash,format=raw,file=$RUN/nor.bin" \
  >"$W/logs/qemu-last.log" 2>&1 &
QPID=$!
echo "qemu pid $QPID  |  serial log: $LOG  |  QMP: $QMP"

# Helper: after SpringBoard is up, set Auto-Lock to Never (otherwise the
# device auto-sleeps after 1 minute and never wakes), and quit QEMU once the
# guest has been shut down with "slide to power off".
(
  booted=0
  while kill -0 $QPID 2>/dev/null; do
    if [ $booted = 0 ] && grep -q "Couldn't get IAP TV out" "$LOG" 2>/dev/null; then
      booted=1
      if [ $FIX_AUTOLOCK = 1 ]; then
        sleep 4
        $INPUT "$QMP" tap 198 160; sleep 2    # Settings
        $INPUT "$QMP" tap 150 226; sleep 2    # General
        $INPUT "$QMP" tap 150 272; sleep 2    # Auto-Lock
        $INPUT "$QMP" tap 150 316; sleep 1.5  # Never
        $INPUT "$QMP" key h >/dev/null        # back to the home screen
        echo "Auto-Lock set to Never"
      fi
    fi
    if grep -q "pmu go stdby" "$LOG" 2>/dev/null; then
      echo "guest powered off - closing QEMU"; $INPUT "$QMP" quit >/dev/null 2>&1; break
    fi
    sleep 1
  done
) &
HPID=$!
wait $QPID
