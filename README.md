# ios-emu-linux

Getting Apple's iOS running under QEMU on a **Linux** host (tested on Arch/Garuda, KDE Plasma 6 Wayland,
Ryzen 7800X3D). This repo holds the launch scripts, notes and small patches. It contains **no Apple
firmware, kernels, bootroms or disk images**: you fetch those yourself (see each folder's README).

**New here? Start with [GUIDE.md](GUIDE.md)**: which emulator to pick, what PC you need, setup overview, controls, troubleshooting and a glossary.

| Folder | What | Status |
|---|---|---|
| [`ios12-xnu-qemu/`](ios12-xnu-qemu/) | iOS 12.1 on an emulated iPhone 6s Plus, using [alephsecurity/xnu-qemu-arm64](https://github.com/alephsecurity/xnu-qemu-arm64) | ✅ boots to a root shell; kernel console in a window; SSH from the host. No home screen (the fork has no display/GPU/touch emulation) |
| [`ipod-touch-1g/`](ipod-touch-1g/) | iPhoneOS 1.0 on an emulated iPod touch 1G, using [devos50/qemu-ios](https://github.com/devos50/qemu-ios) | ✅ home screen, touch via mouse, apps run |
| [`iphone11-qemuapplesilicon/`](iphone11-qemuapplesilicon/) | iOS 14 on an emulated iPhone 11, using [ChefKiss Inferno](https://github.com/ChefKissInc/Inferno) | ✅ home screen, touch, root shell, internet, apt, self-built app installed |

## Install the emulators (Arch Linux packages)

Each emulator is packaged for Arch Linux and Arch-based distributions (Garuda, EndeavourOS, CachyOS, Manjaro).
The packages install into their own folder under `/opt`, so they sit **beside** the normal `qemu` packages and
never replace them. They contain only the emulator and launchers: **no Apple files**.

| Package | For | Command / menu entry | Your files go in |
|---|---|---|---|
| [`qemu-apple-t8030-git`](packaging/arch/qemu-apple-t8030-git/) | iPhone 11, iOS 14 (Inferno) | `qemu-apple-t8030`, menu "QEMU t8030" | `~/.local/share/qemu-apple-t8030/` |
| [`qemu-ios-ipod-git`](packaging/arch/qemu-ios-ipod-git/) | iPod touch 1G, iPhoneOS 1.0 (qemu-ios) | `ipod-touch-qemu`, menu "iPod touch 1G" | `~/.local/share/qemu-ios-ipod/` |
| [`xnu-qemu-arm64-git`](packaging/arch/xnu-qemu-arm64-git/) | iOS 12.1 shell, iPhone 6s Plus (xnu-qemu-arm64) | `xnu-qemu-ios`, `xnu-qemu-ios-ssh` | `~/.local/share/xnu-qemu-arm64/` |

Three ways to get them (pick one):

1. **From the AUR** with an AUR helper, for example `yay -S qemu-apple-t8030-git`. This builds on your PC (10-30 minutes each).
2. **Ready-made, from the [Releases page](https://github.com/eugenesflanagin-spec/ios-emu-linux/releases)**: download the
   `.pkg.tar.zst` you want plus `SHA256SUMS`, then
   `sha256sum -c SHA256SUMS --ignore-missing && sudo pacman -U ./qemu-apple-t8030-git-*.pkg.tar.zst`
3. **From this repo:** `cd packaging/arch/<package> && makepkg -si` (the t8030 package also needs
   [`lzfse`](https://aur.archlinux.org/packages/lzfse) from the AUR to build).

Run the command once without any files set up: it tells you exactly which files it expects and where.
[GUIDE.md](GUIDE.md) section 3 explains the packages in plain English.

## Linux-specific fixes in here
- **xnu-qemu-arm64:** the guest-services socket layer assumed a macOS host (sockaddr layout, `O_NONBLOCK`
  value, errno numbers). `ios12-xnu-qemu/patches/` translates them so Aleph's tcp-tunnel / SSH works on
  Linux, and fixes the ramfb format (it was advertised as 16 bpp but displayed as 24 bpp).
- **tcp-tunnel without Xcode:** `ios12-xnu-qemu/tunnel-linux/` cross-builds the iOS-side tunnel with
  `clang -target arm64-apple-ios12.0`, a few hand-written minimal headers, `ld64.lld` and a stub
  `libSystem.tbd`, then signs it with `ldid`. No Apple SDK is needed.
- **qemu-ios (iPod):**
  - the NAND is about 133k small files, so the launcher unpacks it to `/dev/shm`
  - SDL3's sdl2-compat hangs on X11, so the launcher forces Wayland
  - Auto-Lock is set to Never on every boot, because the device never wakes from sleep (upstream issue)

## Credits

This repo only glues things together; the emulators are other people's work:
- **[Inferno](https://github.com/ChefKissInc/Inferno)** by ChefKiss and contributors: the iPhone 11 (t8030) emulator
  and its [setup guide](https://chefkiss.dev/applehax/inferno/). The package here is an *unofficial* build: as
  ChefKiss's branding notice asks, it ships without their artwork and name.
- **[qemu-ios](https://github.com/devos50/qemu-ios)** by Martijn de Vos (devos50) and contributors: the iPod touch emulator
  and its system files.
- **[xnu-qemu-arm64](https://github.com/alephsecurity/xnu-qemu-arm64)** and
  [xnu-qemu-arm64-tools](https://github.com/alephsecurity/xnu-qemu-arm64-tools) by Aleph Security (Jonathan Afek and
  contributors): iOS 12 on QEMU, the tcp-tunnel and the guide.
- **[QEMU](https://www.qemu.org)**, which all three are built on.
- Tools used along the way: [ldid](https://github.com/ProcursusTeam/ldid), [libimobiledevice](https://libimobiledevice.org)
  and idevicerestore, [linux-apfs-rw](https://github.com/linux-apfs/linux-apfs-rw), [apfs-fuse](https://github.com/sgan81/apfs-fuse),
  [mlib](https://github.com/P-p-H-d/mlib).

## Licences
Scripts and docs: MIT (see `LICENSE`). Files under `*/patches/` and the `.patch` files under `packaging/` modify
QEMU and are under the licence of the code they patch (GPL-2.0-or-later for QEMU and qemu-ios / xnu-qemu-arm64,
GPL-3.0 / AGPL-3.0 for Inferno). The packages carry each emulator's own licence files. Screenshots show Apple software and are included for documentation only.
