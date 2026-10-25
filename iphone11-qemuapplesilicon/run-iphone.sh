#!/bin/bash
# iPhone 11 (t8030) running iOS 14.0 beta 5 under ChefKiss Inferno (QEMU fork).
#
#   ./run-iphone.sh               normal boot in a GTK window (touch = mouse, keys below)
#   ./run-iphone.sh --companion   also start the companion VM first (USB link: needed for
#                                 idevice* tools / reverse tethering; not needed for the GUI)
#   ./run-iphone.sh --headless    no window (egl-headless); drive it with tools/qin.py
#
# Buttons: F1 force shutdown | F2 ringer | F3 vol- | F4 vol+ | F5 side/power | F6 Home
#          F6 once = Home screen, F6 twice = app switcher,
#          SOS / slide-to-power-off = hold F4, then ~0.5 s later also hold F5.
# NEVER: set a passcode, enable Location Services, or use "Erase All Content and Settings"
#        (the last one bricks the install).  Quit: close the window or F1 (force shutdown).
# A normal boot reaches the lock/setup screen in ~2-3 minutes (pure TCG, software rendering).

D="$(cd "$(dirname "$0")" && pwd)"
DISPLAY_ARGS=(-display gtk,zoom-to-fit=on,show-cursor=on)
COMPANION=0
for a in "$@"; do
  case "$a" in
    --companion) COMPANION=1 ;;
    --headless) DISPLAY_ARGS=(-display egl-headless) ;;
    -h|--help) sed -n 2,16p "$0"; exit 0 ;;
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
"$Q" -name "iPhone 11 - iOS 14 (Inferno)" "${MAINARGS[@]}" "${DISPLAY_ARGS[@]}" \
  -serial "file:$D/logs/serial-main.log" \
  -monitor "unix:$D/logs/mon-main.sock,server,nowait" \
  -qmp "unix:$D/logs/qmp-main.sock,server,nowait"
rc=$?
if [ $COMPANION = 1 ]; then "$D/mon.sh" comp quit >/dev/null 2>&1; fi
exit $rc
