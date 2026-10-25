#!/bin/bash
# iPhone 11 (t8030) running iOS 14.0 beta 5 under ChefKiss Inferno (QEMU fork).
#
#   ./run-iphone.sh               normal boot in a GTK window (touch = mouse, keys below).
#                                 The window opens at 0.65x (538x1165 phone + menubar,
#                                 ~1226 px tall = 85% of the 1440p main screen) and is
#                                 moved to the centre of the primary monitor (kdotool).
#                                 0.65x is drawn by cairo's box filter: sharp, no jaggies.
#                                 View > Zoom In/Out/Best Fit changes it at run time.
#   ./run-iphone.sh --companion   also start the companion VM first (USB link: needed for
#                                 idevice* tools / reverse tethering; not needed for the GUI)
#   ./run-iphone.sh --headless    no window (egl-headless); drive it with tools/qin.py
#
# Mouse:   left click/drag = finger | MIDDLE click = Home (same as F6; double = app switcher;
#          patched multitouch device, see patches-local/0001-mt-spi-middle-click-home.patch)
# Buttons: F1 force shutdown | F2 ringer | F3 vol- | F4 vol+ | F5 side/power | F6 Home
#          F6 once = Home screen, F6 twice = app switcher,
#          SOS / slide-to-power-off = hold F4, then ~0.5 s later also hold F5.
# NEVER: set a passcode, enable Location Services, or use "Erase All Content and Settings"
#        (the last one bricks the install).  Quit: close the window or F1 (force shutdown).
# A normal boot reaches the lock/setup screen in ~2-3 minutes (pure TCG, software rendering).

D="$(cd "$(dirname "$0")" && pwd)"
SCALE=0.65   # 1792 * 0.65 = 1165 px of phone screen; 0.25..4 allowed
DISPLAY_ARGS=(-display gtk,zoom-to-fit=off,show-cursor=on,scale=$SCALE)
PLACE=1
COMPANION=0
for a in "$@"; do
  case "$a" in
    --companion) COMPANION=1 ;;
    --headless) DISPLAY_ARGS=(-display egl-headless); PLACE=0 ;;
    -h|--help) sed -n 2,21p "$0"; exit 0 ;;
  esac
done

if [ ! -d "$D/data" ] || [ ! -f "$D/data/root.qcow2" ]; then
  echo "Disk images not found under $D/data (is the 4TB HDD mounted?)" >&2; exit 1
fi
for s in "$D"/logs/mon-*.sock; do
  [ -S "$s" ] || continue; t=$(basename "$s" .sock); t=${t#mon-}; [ "$t" = comp ] && continue
  if "$D/mon.sh" "$t" "info status" 2>/dev/null | grep -q 'VM status'; then
    echo "An iPhone VM ($t) is already running and holds the disk." >&2
    command -v kdialog >/dev/null && (kdialog --sorry "An iPhone VM ($t) is already running." &) 2>/dev/null
    exit 1
  fi
done

if [ $COMPANION = 1 ]; then
  rm -f "$D/logs/companion-idle.log"
  setsid nohup "$D/companion/run-companion.sh" idle > "$D/logs/comp-run.out" 2>&1 < /dev/null &
  for i in $(seq 30); do grep -q 'waiting for Apple USB' "$D/logs/companion-idle.log" 2>/dev/null && break; sleep 1; done
fi

source "$D/vm-args.sh"   # sets Q, MAINARGS, cd's into data/
mkdir -p "$D/logs"
rm -f "$D/logs/mon-main.sock" "$D/logs/qmp-main.sock"
# Wayland apps can't place their own window: once it appears, centre it on the
# primary (priority 1) monitor.  Best effort; silently does nothing on failure.
place_window() {
  command -v kdotool >/dev/null || return
  local w="" i geo
  for i in $(seq 120); do
    w=$(kdotool search --name 'iPhone 11 - iOS 14' 2>/dev/null | head -1); [ -n "$w" ] && break; sleep 0.5
  done
  [ -n "$w" ] || return
  sleep 0.5
  geo=$(kscreen-doctor -j 2>/dev/null | python3 -c '
import json,sys
o=[o for o in json.load(sys.stdin)["outputs"] if o.get("enabled")]
o.sort(key=lambda o: o.get("priority") or 99)
print(o[0]["pos"]["x"], o[0]["pos"]["y"], o[0]["size"]["width"], o[0]["size"]["height"])' 2>/dev/null)
  [ -n "$geo" ] || geo="1920 0 2560 1440"
  read -r ox oy ow oh <<<"$geo"
  read -r ww wh < <(kdotool getwindowgeometry "$w" | awk '/Geometry/{split($2,a,"x"); print int(a[1]), int(a[2])}')
  [ -n "$wh" ] || return
  kdotool windowmove "$w" $((ox + (ow - ww) / 2)) $((oy + (oh - wh) / 2)) >/dev/null 2>&1
}
[ $PLACE = 1 ] && { place_window & }
"$Q" -name "iPhone 11 - iOS 14 (Inferno)" "${MAINARGS[@]}" "${DISPLAY_ARGS[@]}" \
  -chardev "socket,id=ser0,path=$D/logs/serial-main.sock,server=on,wait=off,logfile=$D/logs/serial-main.log" -serial chardev:ser0 \
  -monitor "unix:$D/logs/mon-main.sock,server,nowait" \
  -qmp "unix:$D/logs/qmp-main.sock,server,nowait"
rc=$?
if [ $COMPANION = 1 ]; then "$D/mon.sh" comp quit >/dev/null 2>&1; fi
exit $rc
