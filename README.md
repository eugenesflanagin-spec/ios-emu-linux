# ios-emu-linux

Getting Apple's iOS running under QEMU on a **Linux** host (tested on Arch/Garuda, KDE Plasma 6 Wayland,
Ryzen 7800X3D). This repo holds the launch scripts, notes and small patches. It contains **no Apple
firmware, kernels, bootroms or disk images**: you fetch those yourself (see each folder's README).

| Folder | What | Status |
|---|---|---|
| [`ios12-xnu-qemu/`](ios12-xnu-qemu/) | iOS 12.1 on an emulated iPhone 6s Plus, using [alephsecurity/xnu-qemu-arm64](https://github.com/alephsecurity/xnu-qemu-arm64) | ✅ boots to a root shell; kernel console in a window; SSH from the host. No home screen (the fork has no display/GPU/touch emulation) |
| [`ipod-touch-1g/`](ipod-touch-1g/) | iPhoneOS 1.0 on an emulated iPod touch 1G, using [devos50/qemu-ios](https://github.com/devos50/qemu-ios) | ✅ home screen, touch via mouse, apps run |
| [`iphone11-qemuapplesilicon/`](iphone11-qemuapplesilicon/) | iOS 14 on an emulated iPhone 11, using [ChefKiss Inferno](https://github.com/ChefKissInc/Inferno) | ✅ home screen, touch, root shell, internet, apt, self-built app installed |

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

## Licences
Scripts and docs: MIT (see `LICENSE`). Files under `*/patches/` modify QEMU and are GPL-2.0-or-later,
like QEMU itself. Screenshots show Apple software and are included for documentation only.
