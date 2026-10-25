#!/bin/sh
# Build HelloLinux.app for iOS 14 arm64 on Linux: clang + ld64.lld + hand-written .tbd stubs (no Apple SDK).
set -e
cd "$(dirname "$0")"
clang -target arm64-apple-ios14.0 -O2 -fno-stack-protector -c main.c -o main.o
ld64.lld -arch arm64 -platform_version ios 14.0 14.0 -o HelloLinux main.o stubs/*.tbd
rm -rf HelloLinux.app && mkdir HelloLinux.app && cp HelloLinux Info.plist HelloLinux.app/
echo "built $(pwd)/HelloLinux.app (sign with: ldid -S -Idev.local.hellolinux HelloLinux.app/HelloLinux)"
