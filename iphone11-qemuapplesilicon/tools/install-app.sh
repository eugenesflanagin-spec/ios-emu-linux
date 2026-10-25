#!/bin/bash
# install-app.sh /path/To.app [bundle.id]
# Fake-signs a self-built / open-source .app with ldid, serves it from the companion VM over the
# reverse-tether link and installs it on the running iPhone (/Applications + uicache) via the
# serial root shell.  Needs: iPhone VM running ("main" tag, i.e. ./run-iphone.sh --companion).
# Never use App Store / decrypted IPAs.
set -e
D="${D:-$(cd "$(dirname "$0")/.." && pwd)}"
LDID="${LDID:-ldid}"
T=${TAG:-main}
APP=$(readlink -f "${1:?usage: install-app.sh To.app [bundle.id]}"); NAME=$(basename "$APP")
BID=${2:-$(python3 -I -c "import plistlib,sys; print(plistlib.load(open(sys.argv[1],'rb'))['CFBundleIdentifier'])" "$APP/Info.plist")}
EXE=$(python3 -I -c "import plistlib,sys; print(plistlib.load(open(sys.argv[1],'rb'))['CFBundleExecutable'])" "$APP/Info.plist")
W=$(mktemp -d); cp -r "$APP" "$W/"
find "$W/$NAME" -type f | while read -r f; do file "$f" | grep -q Mach-O && "$LDID" -S -I"$BID" "$f"; done
mkdir -p $D/data/www; (cd "$W" && tar -cf "$D/data/www/$NAME.tar" "$NAME"); rm -rf "$W"
$D/comp-run.sh "pgrep -f 'http.server 8080' >/dev/null || (cd /mnt/data/www && setsid python3 -m http.server 8080 --bind 192.168.66.1 >/tmp/http.log 2>&1 &)" 15 >/dev/null
$D/tools/ios-sh.sh $T "export PATH=/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin; mount -uw /; cd /tmp && wget -q http://192.168.66.1:8080/$NAME.tar -O app.tar && rm -rf /Applications/$NAME && tar -xf app.tar -C /Applications && chown -R 0:80 /Applications/$NAME && uicache -p /Applications/$NAME && echo INSTALLED_$EXE" 30 | grep -E "INSTALLED_|rror"
