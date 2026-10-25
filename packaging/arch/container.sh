#!/bin/bash
# Build and install-test the Arch packages in clean archlinux:base-devel containers.
# The GitHub Actions release workflow runs exactly these commands; you can run them
# on your own PC too (needs docker or podman).
#
#   packaging/arch/container.sh build PKGNAME OUTDIR
#       Builds PKGNAME (a folder next to this script) in a fresh container with
#       makepkg -s, so missing makedepends/depends show up as a failed build.
#       Writes the .pkg.tar.zst, the PKGBUILD with the final pkgver, its .SRCINFO,
#       a source tarball (makepkg --source) and namcap's report into OUTDIR.
#   packaging/arch/container.sh test OUTDIR [PKGNAME...]
#       Installs the packages from OUTDIR in another fresh container and checks that
#       the emulators start (--version, -machine help) and that the launchers stop
#       cleanly with their "files missing" message. Nothing is booted: no Apple
#       files exist in the container.
#
# Environment: JOBS (parallel jobs, default nproc), SRCDEST (host folder to keep the
# git clones between runs, optional), CONTAINER_NAME, ENGINE (docker|podman).
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
engine=${ENGINE:-$(command -v docker >/dev/null && echo docker || echo podman)}
image=${ARCH_IMAGE:-archlinux:base-devel}
packager=${PACKAGER:-Eugene Flanagin <eflanagin@pm.me>}

run() { # run MODE OUTDIR ARGS...
  local mode=$1 out; out=$(realpath -m "$2"); shift 2
  mkdir -p "$out"
  local extra=()
  [ -n "${SRCDEST:-}" ] && { mkdir -p "$SRCDEST"; extra+=(-v "$(realpath "$SRCDEST"):/srcdest"); }
  [ -n "${CONTAINER_NAME:-}" ] && extra+=(--name "$CONTAINER_NAME")
  "$engine" run --rm "${extra[@]}" \
    -v "$here:/pkgs:ro" -v "$out:/out" \
    -e JOBS="${JOBS:-$(nproc)}" -e PACKAGER="$packager" -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" \
    "$image" bash /pkgs/container.sh "inside-$mode" "$@"
}

aur_build() { # build + install an AUR-only makedepend as the builder user
  local name=$1
  su builder -c "cd ~ && git clone -q https://aur.archlinux.org/$name.git aur-$name && cd aur-$name && makepkg -si --noconfirm --needed" >/dev/null
}

inside_build() {
  local pkg=$1
  pacman -Syu --noconfirm --needed base-devel git sudo namcap >/dev/null
  useradd -m builder
  echo 'builder ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/builder
  # AUR-only build dependencies
  case $pkg in qemu-apple-t8030-git) aur_build lzfse ;; esac
  cp -r "/pkgs/$pkg" /home/builder/pkg
  chown -R builder: /home/builder/pkg
  local srcdest=""
  if [ -d /srcdest ]; then chown builder: /srcdest; srcdest="SRCDEST=/srcdest"; fi
  su builder -c "cd ~/pkg && env $srcdest MAKEFLAGS=-j$JOBS PACKAGER='$PACKAGER' nice -n 15 makepkg -fCs --noconfirm"
  cd /home/builder/pkg
  su builder -c "cd ~/pkg && makepkg --printsrcinfo > .SRCINFO && env $srcdest makepkg --source -f >/dev/null"
  [ -d /srcdest ] && chown -R "$HOST_UID:$HOST_GID" /srcdest
  cp ./*.pkg.tar.zst ./*.src.tar.gz /out/
  cp PKGBUILD "/out/$pkg.PKGBUILD"; cp .SRCINFO "/out/$pkg.SRCINFO"
  { echo "== namcap PKGBUILD"; namcap PKGBUILD; echo "== namcap package"; namcap ./*.pkg.tar.zst; } > "/out/$pkg.namcap.txt" 2>&1 || true
  cat "/out/$pkg.namcap.txt"
  chown -R "$HOST_UID:$HOST_GID" /out
}

check() { echo "+ $*"; "$@"; }
expect_fail_msg() { # expect_fail_msg PATTERN CMD...: CMD must exit non-zero and print PATTERN
  local pat=$1; shift; local o rc=0
  o=$("$@" </dev/null 2>&1) || rc=$?
  if [ $rc -eq 0 ] || ! grep -q "$pat" <<<"$o"; then echo "FAIL: $* (rc=$rc)"; echo "$o"; return 1; fi
  echo "ok: $* -> exit $rc, says '$pat'"
}

inside_test() {
  pacman -Syu --noconfirm --needed desktop-file-utils >/dev/null
  local want=("$@") pkgs=()
  [ ${#want[@]} -eq 0 ] && want=(qemu-ios-ipod-git xnu-qemu-arm64-git qemu-apple-t8030-git)
  for p in "${want[@]}"; do
    pkgs+=("$(ls /out/"$p"-[0-9]*-x86_64.pkg.tar.zst | head -1)")
  done
  check pacman -U --noconfirm "${pkgs[@]}"
  useradd -m tester
  local T="su tester -c"
  for p in "${want[@]}"; do
    echo "=== $p"
    pacman -Qi "$p" | grep -E '^(Version|Packager|Depends On)'
    case $p in
      qemu-ios-ipod-git)
        q=/opt/qemu-ios-ipod/bin/qemu-system-arm
        check $q --version
        $q -machine help | grep '^iPod-Touch'
        check bash -n /usr/bin/ipod-touch-qemu
        check python3 -I -c 'import ast,sys; ast.parse(open(sys.argv[1]).read())' /opt/qemu-ios-ipod/libexec/ipod-input.py
        expect_fail_msg 'system files are missing' $T ipod-touch-qemu
        check desktop-file-validate /usr/share/applications/ipod-touch-qemu.desktop
        ;;
      xnu-qemu-arm64-git)
        q=/opt/xnu-qemu-arm64/bin/qemu-system-aarch64
        check $q --version
        $q -machine help | grep '^iPhone6splus-n66-s8000'
        for s in xnu-qemu-ios xnu-qemu-ios-console xnu-qemu-ios-ssh; do check bash -n /usr/bin/$s; done
        expect_fail_msg 'not set up yet' $T xnu-qemu-ios
        check desktop-file-validate /usr/share/applications/xnu-qemu-ios.desktop
        ;;
      qemu-apple-t8030-git)
        q=/opt/qemu-apple-t8030/bin/qemu-system-aarch64
        check $q --version
        if $q --version | grep 'ChefKiss Inferno'; then echo "FAIL: upstream branding in --version"; return 1; fi
        $q -machine help | grep '^t8030'
        for s in qemu-apple-t8030 qemu-apple-t8030-set-boot-splash; do check bash -n /usr/bin/$s; done
        check $T 'qemu-apple-t8030 --help' >/dev/null
        expect_fail_msg 'No VM set up yet' $T qemu-apple-t8030
        check desktop-file-validate /usr/share/applications/qemu-apple-t8030.desktop
        cmp /opt/qemu-apple-t8030/share/icons/hicolor/512x512/apps/CKQEMUBootSplash@2x.png /pkgs/qemu-apple-t8030-git/boot-splash.png
        echo "ok: boot splash is the replacement picture, not the upstream artwork"
        ;;
    esac
    # every ELF in the package must resolve all its libraries
    local bad=0 f
    while read -r f; do
      [ -f "$f" ] && head -c4 "$f" | grep -q ELF || continue
      if ldd "$f" | grep -q 'not found'; then echo "FAIL: $f"; ldd "$f" | grep 'not found'; bad=1; fi
    done < <(pacman -Qlq "$p")
    [ $bad -eq 0 ] || return 1
    echo "ok: all ELF files resolve their libraries"
  done
  echo "ALL TESTS PASSED"
}

case ${1:-} in
  build) shift; [ $# -eq 2 ] || { echo "usage: $0 build PKGNAME OUTDIR" >&2; exit 2; }; run build "$2" "$1" ;;
  test) shift; out=$1; shift; run test "$out" "$@" ;;
  inside-build) shift; inside_build "$@" ;;
  inside-test) shift; set -o pipefail; inside_test "$@" ;;
  *) sed -n 2,19p "$0"; exit 2 ;;
esac
