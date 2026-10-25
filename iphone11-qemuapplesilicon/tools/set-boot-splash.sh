#!/bin/bash
# set-boot-splash.sh IMAGE | --github USER | --restore
# Replaces the boot splash Inferno draws before iOS starts with your own picture (fitted onto a
# 1024x1024 black square, transparency kept clean). The original artwork is backed up once as
# *.orig-chefkiss and --restore puts it back. Takes effect on the next boot; no rebuild needed.
# Inferno's ui/icons/CKBrandingNotice.md: the artwork is (c) ChefKiss and modified builds must drop it,
# so this is also the easy way to de-brand a local build. Never redistribute their artwork.
set -e
D="${D:-$(cd "$(dirname "$0")/.." && pwd)}"
F="$D/src/ui/icons/CKQEMUBootSplash_512x512@2x.png"   # the build's qemu-bundle copy is a symlink to this
[ -f "$F" ] || { echo "splash not found: $F (set D= to your Inferno folder)" >&2; exit 1; }
[ -e "$F.orig-chefkiss" ] || cp -p "$F" "$F.orig-chefkiss"
case "${1:?usage: set-boot-splash.sh IMAGE | --github USER | --restore}" in
  --restore) cp "$F.orig-chefkiss" "$F"; echo "restored original splash"; exit 0 ;;
  --github) W=$(mktemp -d); curl -fsSL --max-time 30 -o "$W/in.png" "https://github.com/${2:?github user}.png?size=1024"; IN="$W/in.png" ;;
  *) IN=$(readlink -f "$1") ;;
esac
magick "$IN" -resize 1024x1024 -background black -gravity center -extent 1024x1024 -alpha remove -alpha on "PNG32:$F"
[ -n "$W" ] && rm -rf "$W"
echo "boot splash set from $1${2:+ $2}"
