# iOS 12.1 on QEMU (Aleph Security xnu-qemu-arm64) — iPhone 6s Plus (n66)

Boots the **iOS 12.1 (16B92)** kernelcache to an **interactive root bash shell**
(`bash-4.4#`) on the serial console, following Aleph Security's guide:
https://github.com/alephsecurity/xnu-qemu-arm64/wiki/Build-iOS-on-QEMU

Built and verified on Arch (kernel 7.3.0-tkg) on 2026-10-24.

## Run it
    ./run-ios.sh            # SCREEN MODE (default since 2026-10-24)
A QEMU window shows the iOS text framebuffer (verbose kernel boot, launchd log, then the
root shell). **The terminal you started it from is the keyboard** (serial input); what you
type appears in the window. After ~70 s press Enter for `bash-4.4#`. Inside the shell:
    export PATH=$PATH:/iosbinpack64/usr/bin:/iosbinpack64/bin:/iosbinpack64/usr/sbin:/iosbinpack64/sbin
Quit with **Ctrl-a x** in the terminal (Ctrl-a c = QEMU monitor) or close the window.

    ./run-ios-console.sh    # old serial-only mode: no window, everything in the terminal
    ./ssh-ios.sh [cmd]      # SSH in (root / alpine) via Aleph's tcp-tunnel on host port 2222;
                            # works in both modes ~25 s after start (needs sshpass)
    scp -P 2222 file root@127.0.0.1:/private/var/   # file transfer (root fs is read-only)

Also from the KDE menu: **More Programs > Emulators > Retro Machines >
"iOS 12 (QEMU, iPhone 6s Plus)"** (Konsole = keyboard, QEMU window = screen).

## Screen + SSH (added 2026-10-24, QEMU branch `ios-screen`, commit 34d7808)
- Screenshots: screenshots/ramfb-gtk-shell-20261024.png (shell on the framebuffer, GTK run),
  screenshots/ramfb-verbose-boot-20261024.png, screenshots/ramfb-bash-shell-20261024.png,
  screenshots/ramfb-16bpp-wrong-colors-before-fix-20261024.png (the stock fork's output).
- The stock `xnu-ramfb=on` did NOT crash: it boots fine, but with a framebuffer XNU moves the
  console to the screen, so the serial log just stops at "IOSurface disallowing global lookups"
  (input still comes from serial because of `serial=2`). The stock fork passed 16-bpp boot args
  but displayed the buffer as 24-bpp r8g8b8 -> magenta text. Fixed: 32 bpp / x8r8g8b8.
- SSH: `/bin/tunnel` (Aleph tcp-tunnel) is now in hfs.main with
  /System/Library/LaunchDaemons/tcptunnel.plist (`2222:127.0.0.1:22`). It was cross-built ON
  LINUX WITHOUT ANY APPLE SDK: clang -target arm64-apple-ios12.0 + hand-written minimal Darwin
  headers + ld64.lld linked against a hand-written libSystem.tbd stub, signed with ldid
  (tunnel-linux/build.sh). The fork's host side assumed a macOS host; patched for Linux
  (Darwin sockaddr layout, O_NONBLOCK value, errno numbers, BSD accept() non-blocking inherit).
- Backups: qemu/aarch64-softmmu/qemu-system-aarch64.working (stock binary),
  build/hfs.main.bak-20261024 + build/hfs.sec.bak-20261024 (btrfs reflinks, pre-tunnel),
  run-ios.sh.bak-20261024, QEMU `master` branch untouched.
- Proof: `./ssh-ios.sh 'echo SSH_PROOF $(id -un) $(uname -snrm)'` ->
  `SSH_PROOF root Darwin localhost 18.2.0 iPhone8,2`

## GUI / SpringBoard status (investigated 2026-10-24)
SpringBoard (pid 35) and backboardd (pid 38) are launched by launchd, IOMobileFramebuffer
and AGXFirmwareKextG5P classes exist, but nobody opens a framebuffer user client: there is no
emulated display controller (CLCD/DCP), GPU (AGX/Metal), touch (multitouch/SPI) or HID
keyboard device in this machine model. The ramfb is only XNU's early text console.
Upstream issues #5/#12 ("display and touch", "GUI") have been open since 2019/2020 with no
progress; the fork is dormant. Reaching a usable home screen would need new emulated
hardware + reverse engineering of Apple's display stack - not realistic in this tree.

## Proof of boot (serial console, final run)
    bash-4.4# echo PROOF_UID=$(id -u) PROOF_UNAME="$(uname -a)"
    PROOF_UID=0 PROOF_UNAME=Darwin localhost 18.2.0 Darwin Kernel Version 18.2.0: \
      Tue Oct 16 21:02:23 PDT 2018; root:xnu-4903.222.5~1/RELEASE_ARM64_S8000 iPhone8,2

Root (UID 0), Darwin 18.2.0 / xnu-4903.222.5, machine iPhone8,2 (iPhone 6s Plus).

## Final artifacts (build/)
- kernelcache.release.n66.out   decoded+decompressed iOS 12.1 kernelcache (Mach-O arm64)
- DeviceTree.n66ap.im4p.out     decoded device tree
- aleph_bdev_drv.bin            custom block-device driver (self-built)
- hfs.main (6 GB HFS+)          root fs: full iOS rootfs + patched/re-signed launchd +
                                iosbinpack64 + LaunchDaemons (bash, mount_sec, dropbear) +
                                edited fstab, keybagd removed, /private/var cleared
- hfs.sec  (2 GB HFS+)          secondary r/w disk: /private/var + /dropbear

## Versions / commits used
- QEMU fork  alephsecurity/xnu-qemu-arm64   @ 2694993  (reports as QEMU 4.2.0)
- tools      alephsecurity/xnu-qemu-arm64-tools @ 92fd8db
- xnu headers apple-oss-distributions/xnu  tag xnu-4903.221.2 (iOS 12.1 era; for driver build)
- rootlessJB jakeajames/rootlessJB @ 9de6d12  (iosbinpack64: bash, dropbear, coreutils)
- ldid       ProcursusTeam/ldid   @ af86971   (ad-hoc Mach-O signer; replaces macOS jtool)
- IPSW       iPhone_5.5_12.1_16B92_Restore.ipsw, downloaded from Apple:
             http://updates-http.cdn-apple.com/2018FallFCS/fullrestores/091-91479/\
             964118EC-D4BE-11E8-BC75-A45C715A3354/iPhone_5.5_12.1_16B92_Restore.ipsw

## System packages relied on (already installed; all official repo/AUR)
base-devel, python, glib2, pixman, meson, ninja, dmg2img, hfsprogs (mkfs.hfsplus/
fsck.hfsplus), apfs-fuse (AUR), aarch64-linux-gnu-gcc/binutils, llvm (llvm-nm/
llvm-objdump), libplist, openssl, fuse3. No system qemu package was touched; the fork
runs only from this directory. Nothing was `make install`-ed into /usr or /usr/local.

## How it was built (summary)
1. Download IPSW from Apple; unzip. kernelcache = APFS/ASN1 decode + lzss decompress;
   device tree + ramdisk decoded with the alephsecurity bootstrap_scripts (Python 3).
2. QEMU fork configured with `--disable-pie --disable-slirp --disable-capstone
   --disable-werror --disable-nettle --disable-libnfs/libiscsi/glusterfs/rbd/curl/libssh
   --disable-vnc --disable-docs` (the extra disables work around modern library APIs and
   Sphinx that break this 2020-era tree on current Arch). Built `aarch64-softmmu/all`.
3. Block-device driver built with the aarch64-linux-gnu cross toolchain (the guide's
   aarch64-none-elf Homebrew toolchain is macOS-only) against xnu-4903.221.2 headers and
   kernel symbols from `llvm-nm` (ELF binutils nm can't read the Mach-O kernelcache).
4. Disk prep (Linux equivalents of the macOS hdiutil/diskutil/rsync flow):
   - OS rootfs dmg -> raw with `dmg2img`; APFS system volume mounted read-only with
     `apfs-fuse`.
   - `mkfs.hfsplus` a fresh 6 GB (main) and 2 GB (sec) HFS+ image, loop-mounted rw with
     the Linux hfsplus driver (no journal), rootfs copied in with `rsync -aH` (Apple
     xattrs like com.apple.decmpfs are intentionally dropped; apfs-fuse already returns
     decompressed data).
   - launchd patched at VA 0x10002fb18 (`cset w20,ne` -> `mov w20,#1`, bytes
     1a9f07f4 -> 52800034 at file offset 0x2fb18) with a scripted byte-patch (the guide
     does this by hand in Ghidra), then **ad-hoc re-signed with ldid** carrying its
     original entitlement `com.apple.private.kernel.system-override`.
   - LaunchDaemons: bash.plist, mount_sec.plist, dropbear.plist added; fstab replaced;
     com.apple.mobile.keybagd.plist removed; /private/var cleared (lives on hfs.sec).

## Skipped / workarounds / notes
- **jtool signing**: NOT needed and skipped. The QEMU machine patches the kernel's
  CORE_TRUST_CHECK to `mov w0,#1` at load (n66_iphone6splus.c), disabling Core Trust, so
  ad-hoc signatures run. BUT a binary whose *existing* Apple signature no longer matches
  its (patched) code is still CS_KILLED — so the patched launchd MUST be re-signed. ldid
  (open-source) does this on Linux in place of the guide's macOS jtool.
- **tcptunnel / SSH-over-tunnel**: originally skipped ("needs Xcode"); DONE 2026-10-24 with an
  SDK-free Linux cross-build, see "Screen + SSH" above.
- **Disable-ASLR-for-dyld wiki page** (static trust cache + dyld patch): not applied; it is
  an optional extra that also depends on the legacy trust-cache path, which the kernel
  Core-Trust patch makes unnecessary for booting to the shell.
- **Linux tooling substitutions vs the macOS guide**: dmg2img+apfs-fuse (not hdiutil),
  mkfs.hfsplus/Linux hfsplus rw (not hdiutil resize/attach), rsync -aH (not diskutil
  rsync), scripted byte-patch (not Ghidra GUI), ldid (not jtool), aarch64-linux-gnu-
  (not the Homebrew aarch64-none-elf), llvm-nm (not macOS nm), fsck.hfsplus to re-clean
  hfs.sec (not the mac re-attach/detach).
- Many iOS system daemons crash/respawn in the log (SIGSEGV, missing frameworks, no RTC).
  That is expected under QEMU and does not affect the root shell.

## Disk usage
~6.9 GB total in this directory (mostly hfs.main 6 GB + hfs.sec 2 GB share the images;
QEMU source/build ~1.5 GB). The 3.27 GB IPSW and ~5 GB intermediate raw images were
deleted after extraction.

---
Patches in `patches/` apply to alephsecurity/xnu-qemu-arm64 `master` at 2694993 (`git am patches/*.patch`).
