# iPod touch 1G emulator (iPhoneOS 1.0, qemu-ios)

A real graphical early-iPhoneOS emulator: boots an iPod touch 1st gen
(N45AP, iPhoneOS 1.0) to the SpringBoard home screen, with the mouse acting
as the touchscreen. Built on Martijn de Vos (devos50)'s QEMU fork.

Start it from the menu (**Emulators -> iPod touch 1G (iPhoneOS 1.0)**) or run:

    ./run-ipod.sh               # window (SDL, native Wayland)
    ./run-ipod.sh --headless    # no window; drive it over QMP
    ./run-ipod.sh --keep-autolock   # skip the automatic Auto-Lock fix

Boot to the home screen takes about 5 seconds.

## Controls

| Input | Does |
|---|---|
| Mouse click / drag in the window | Finger tap / swipe |
| **H** | Home button |
| **P** held ~5 s | "slide to power off" (then drag the slider). QEMU closes by itself once the guest is off. |
| **P** short press | Sleep. **Don't**: the device never wakes up again (upstream issue #19). Close the window and relaunch. |

## What happens on every launch (and why)

1. A fresh copy of the NAND image is unzipped into RAM (`/dev/shm/ipod-touch-1g-<pid>`, ~520 MB),
   and removed when QEMU exits. The NAND is ~133,000 tiny page files; on this NTFS HDD the
   emulator stalled on disk seeks (the Apple logo took minutes and the monitor froze), from RAM it boots in seconds.
2. The emulator **does not keep anything you change**. qemu-ios writes changed NAND pages to
   `*_new.page` files and never reads them back, so every boot starts from the stock image.
   This is how upstream wrote it.
3. Because of (2), the stock 1-minute Auto-Lock comes back every boot, and the auto-sleep can't be
   woken. So about 4 s after SpringBoard is up, the launcher taps
   **Settings -> General -> Auto-Lock -> Never -> Home** for you (takes ~10 s; you'll see it happen).
   Don't touch the screen during those 10 s.

## Files

| Path | What |
|---|---|
| `run-ipod.sh` | Launcher |
| `tools/ipod-input.py` | QMP helper: `tap X Y`, `drag X1 Y1 X2 Y2`, `key h`, `shot file.ppm`, `quit` (screen is 320x480) |
| `src-1g/` | qemu-ios source, branch `ipod_touch_1g` (commit 501c85c); binary `src-1g/build/qemu-system-arm` |
| `files/n45ap/` | System files from the project's own release `n45ap_v1` (see below) |
| `logs/serial-last.log` | Guest serial console (iBoot + kernel + syslog) of the last run |
| `logs/qemu-last.log` | QEMU stderr of the last run |
| `test/*.png` | Screenshots from verification |

System files (all from https://github.com/devos50/qemu-ios/releases/tag/n45ap_v1):

| File | sha256 |
|---|---|
| bootrom_s5l8900 | 220027d6f8ea24603f8c5ad5e920ab553d85a9cd809d79c7e6f6f0eefdc2bc95 |
| iboot_204_n45ap.bin | be6ec3d515b14826612d8a2b588b176b65d9025f1d96adccc470e78a9efa5d45 |
| nor_n45ap.bin | 9f86a537c19c0193e72e52e60d127f4991eca813b037ff833a1ed1ab9c7dad00 |
| nand_n45ap.zip | 32850c2c2756f1a192cd96e225d7319f662a214aee69c3bed06201c46dfa91a2 |

## Rebuilding

The system `CC` is `aocc-clang`, which breaks this QEMU 6.2-era tree, so build with gcc and a
minimal feature set (avoids old io_uring/libnfs API breakage):

    cd src-1g/build
    env -u CC -u CXX ../configure --cc=gcc --cxx=g++ --host-cc=gcc --without-default-features \
      --enable-sdl --enable-tcg --disable-cocoa --target-list=arm-softmmu --disable-capstone \
      --disable-slirp --disable-werror --enable-pie \
      --extra-cflags='-I/usr/include/openssl -Wno-error=int-conversion -Wno-error=incompatible-pointer-types -Wno-error=implicit-function-declaration' \
      --extra-ldflags='-lcrypto'
    env -u CC nice -n 10 make -j16

Local source change: `pc-bios/keymaps/meson.build` looks for `qemu-keymap-disabled-local`
instead of `qemu-keymap`, so the build copies the shipped keymaps instead of regenerating them
with the system qemu-keymap (which fails on current xkeyboard-config). Nothing is installed
system-wide.

## Known issues

- **X11 SDL hang:** this SDL is sdl2-compat on SDL3; its X11 backend hangs forever in
  `SDL_CreateWindow` with this machine (QEMU stops answering, even SIGTERM). The launcher sets
  `SDL_VIDEODRIVER=wayland`. If you ever run it under X11 and it freezes, `kill -9` the qemu PID.
- Sleep / lock is a one-way trip (issue #19). No Wi-Fi, no audio, no persistence.
- The window is the native 320x480; no scaling in this QEMU version's SDL UI.

## Sources

- Repo: https://github.com/devos50/qemu-ios (branch `ipod_touch_1g`)
- Setup guide: https://devos50.github.io/blog/2022/ipod-touch-qemu-pt2/
- Technical write-up: https://devos50.github.io/blog/2022/ipod-touch-qemu/
- iPod touch 2G (experimental, iPhoneOS 2.x): `ipod_touch_2g` branch, RUNNING.md, release `n72ap_v1`. Not set up here.

---
`patches/0001-keymaps-use-shipped-files.patch` applies to devos50/qemu-ios branch `ipod_touch_1g` at 501c85c (`git apply`).
