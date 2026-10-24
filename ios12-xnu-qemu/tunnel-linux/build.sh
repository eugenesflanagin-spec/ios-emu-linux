#!/usr/bin/env bash
# Cross-build Aleph's tcp-tunnel (tools/tcp-tunnel) for iOS arm64 on Linux, with NO Apple SDK:
# clang -target arm64-apple-ios12.0 + hand-written minimal Darwin headers (include/) +
# ld64.lld against a self-written libSystem.tbd stub, then ad-hoc signed with ldid + ent.xml.
set -e
cd "$(dirname "$0")"
RES=$(clang -print-resource-dir); SRC=../tools/tcp-tunnel/src
for f in main qemu-guest-services/general qemu-guest-services/fds qemu-guest-services/socket; do
  clang -target arm64-apple-ios12.0 -nostdinc -isystem "$RES/include" -Iinclude -I../qemu/include \
    -DOUT_OF_TREE_BUILD -fno-stack-check -fno-stack-protector -c "$SRC/$f.c" -o "$(basename $f).o"
done
ld64.lld -arch arm64 -platform_version ios 12.0 12.0 -o tunnel main.o general.o fds.o socket.o libSystem.tbd
../ldid-src/ldid -S../tools/tcp-tunnel/ent.xml tunnel
echo "built $(pwd)/tunnel"
