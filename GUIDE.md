# Running iOS in an emulator on Linux: a plain-English guide

This guide is for anyone who wants an emulated iPhone or iPod touch on a Linux PC. It explains what each of the
three emulators in this repo can do, what kind of computer you need, how the setup goes, how to use the result, and
what to do when it misbehaves. The detailed per-emulator notes are in each folder's README. This page is the overview.

> **Ground rules (please read):** this repo has **no Apple firmware, keys or disk images**, and you must not share
> yours. The iPhone 11 emulator's own guide asks that **setup automation scripts aren't published**, so the setup
> steps below point to that guide and add only the Linux-specific tips it doesn't cover. Download iOS firmware only
> from Apple's own servers. Only install apps you built yourself or that are open source; no App Store, cracked or
> decrypted apps.

---

## 1. Which emulator do you want?

| | **iPhone 11, iOS 14** | **iPod touch 1G, iPhoneOS 1.0** | **iOS 12 shell** |
|---|---|---|---|
| Folder | [`iphone11-qemuapplesilicon/`](iphone11-qemuapplesilicon/) | [`ipod-touch-1g/`](ipod-touch-1g/) | [`ios12-xnu-qemu/`](ios12-xnu-qemu/) |
| Emulator | [ChefKiss Inferno](https://github.com/ChefKissInc/Inferno) | [devos50/qemu-ios](https://github.com/devos50/qemu-ios) | [alephsecurity/xnu-qemu-arm64](https://github.com/alephsecurity/xnu-qemu-arm64) |
| What you see | A real, modern iPhone home screen, with Settings, Safari, Photos and the other stock apps | The original 2007 iPod touch home screen | A text console only (no home screen is possible) |
| Touch | Mouse = finger | Mouse = finger | none |
| Internet | Yes, through a helper VM | No | SSH from your PC only |
| Install your own apps | Yes (self-built, fake-signed) | No | Command-line tools only |
| Keeps your changes | Yes | **No**, every boot starts fresh | Yes |
| Boot time | ~2.5 minutes | ~5 seconds | quick (not timed) |
| Setup effort | **High**: an evening or two | Low: under an hour | Medium |

**If you want "an iPhone on my PC", pick the iPhone 11.** It's also the one that's useful for walking someone through
their phone's settings, although it runs iOS 14, so newer iOS versions have moved some menus around.

---

## 2. What computer you need

The iPhone emulator does everything in software (there's no hardware acceleration for Apple chips on a PC), so it leans
on your CPU and RAM. Your graphics card isn't used.

| | Minimum | Comfortable |
|---|---|---|
| CPU | 8 threads | 8 cores / 16 threads (the iPhone uses 7 emulated cores) |
| RAM | 16 GB | 32 GB (iPhone 4 GB + helper VM 8 GB + your desktop) |
| Free disk | ~25 GB for the iPhone, ~2 GB for the iPod, ~15 GB for iOS 12 | an SSD makes the iPhone boot faster |
| OS | any recent 64-bit Linux | — |
| Desktop | X11 or Wayland | KDE Plasma (the launcher uses `kdotool` to centre the window; it's optional) |

**The system this was built and tested on:**
- AMD Ryzen 7 7800X3D (8 cores / 16 threads), 32 GB DDR5-6000
- AMD Radeon RX 9070 XT (not used by the emulators)
- Arch-based Linux (Garuda, with CachyOS packages), linux-tkg 7.3 kernel
- KDE Plasma 6.8 on Wayland, 2560×1440 main screen
- gcc 16.2; Inferno 1.0.0rc1 (QEMU 10.2.2 base); emulator files kept on a 4 TB HDD (NTFS)

---

## 3. Installing the emulators (the easy way, on Arch Linux)

You don't have to build the emulators yourself any more. Each one is packaged for **Arch Linux** and the distributions
based on it (Garuda, EndeavourOS, CachyOS, Manjaro). On other distributions, build from source as the per-emulator
sections below describe.

**What a package gives you:** the emulator, a launcher command, a menu entry, and the notes. Each one installs into
its own folder under `/opt`, so it **sits beside** your normal `qemu` and never replaces or breaks it.
**What it doesn't give you:** any Apple files. Those you still prepare yourself, as sections 4-6 explain.

| Package | Emulates | Start it with | Put your files in |
|---|---|---|---|
| `qemu-apple-t8030-git` | iPhone 11, iOS 14 (Inferno) | `qemu-apple-t8030` or menu "QEMU t8030" | `~/.local/share/qemu-apple-t8030/` (`data/` + `vm-args.sh`) |
| `qemu-ios-ipod-git` | iPod touch 1G, iPhoneOS 1.0 | `ipod-touch-qemu` or menu "iPod touch 1G" | `~/.local/share/qemu-ios-ipod/` (the 4 system files) |
| `xnu-qemu-arm64-git` | iOS 12.1 text shell, iPhone 6s Plus | `xnu-qemu-ios` (window), `xnu-qemu-ios-console`, `xnu-qemu-ios-ssh` | `~/.local/share/xnu-qemu-arm64/` (the 5 prepared files) |

**Three ways to install** (they all end in the same package):

1. **AUR** (simplest if you already use an AUR helper):
   ```
   yay -S qemu-apple-t8030-git        # or qemu-ios-ipod-git, xnu-qemu-arm64-git
   ```
   This compiles the emulator on your PC. Expect 10-30 minutes for each one.
2. **Ready-made package** from the [Releases page](https://github.com/eugenesflanagin-spec/ios-emu-linux/releases)
   (no compiling). Download the `.pkg.tar.zst` file(s) you want and `SHA256SUMS` into one folder, then in that folder:
   ```
   sha256sum -c SHA256SUMS --ignore-missing      # every file you downloaded must say OK
   sudo pacman -U ./qemu-apple-t8030-git-*.pkg.tar.zst
   ```
   These were built in a clean Arch container with Arch's standard settings, so they run on any x86-64 PC.
3. **Build from this repo:** `cd packaging/arch/qemu-apple-t8030-git && makepkg -si`. The iPhone package needs
   [`lzfse`](https://aur.archlinux.org/packages/lzfse) from the AUR first.

**First run:** start the command once before you've set anything up. It doesn't crash; it tells you exactly which
files it's missing and which folder it looked in. The iPhone and iOS 12 packages also install their notes in
`/usr/share/doc/<package>/`; the iPod launcher prints its own instructions.

**Removing:** `sudo pacman -R qemu-apple-t8030-git` (and so on). Your files in `~/.local/share/...` are left alone.

---

## 4. Setting up the iPhone 11 (iOS 14)

Follow the official guide at **[chefkiss.dev → AppleHax → Inferno](https://chefkiss.dev/applehax/inferno/)** in order.
These are its stages in plain words, with the tips we needed on Linux. More detail is in
[`iphone11-qemuapplesilicon/README.md`](iphone11-qemuapplesilicon/README.md).

1. **Host setup: build the emulator.** With the `qemu-apple-t8030-git` package (section 3) this step is done:
   skip to step 2. If you build it yourself:
   - Build with **gcc**. clang/aocc trip over an LTO-built library.
   - Run `git submodule update --init` first.
   - **Keep debug info on** (`-Ddebug=true`). Turning it off silently removes code the emulator needs, and the
     restore later fails with *"SEP returned zero-length ART"*.
   - Arch package names for the libraries it links against include `glib2 pixman gtk3 libpng libusb sdl2-compat spice
     libslirp`, plus `meson ninja python`.
2. **File setup.**
   - The only supported firmware is **iOS 14.0 beta 5 (18A5351d) for iPhone 11 (iPhone12,1)**, from Apple's servers.
   - The guide also has you prepare the security-chip (SEP) files. Use the **real SEP** setup. The simulated one
     restores fine but then sits on the Apple logo forever.
   - On an NTFS drive, a couple of symlinks in the source tree have to be made by hand, and a **qcow2** root disk
     behaved better than a raw one.
3. **Companion VM.** This is a small Linux VM that plays the part of "a computer the iPhone is plugged into" over a
   virtual USB cable.
   - Give it **8 GB of RAM** and use the **EHCI** USB controller (xHCI is broken).
   - Start `usbmuxd` only **after** the iPhone has shown up on USB. `usbmuxd -U root` avoids needing a special user.
4. **Restore.** This is like restoring a real iPhone in iTunes: idevicerestore in the companion installs iOS onto the
   emulated phone.
   - If you run it with no window, use `-display egl-headless`, **not** `-display none`, or it freezes at "ASR 4%".
   - A busy or RAM-starved host fails partway through. Close heavy apps and try again.
5. **Filesystem patches.** Small edits the guide makes so iOS boots in the emulator.
   - Without a Mac you can do them in place (same-size byte edits).
   - Adding new files needs a read-write APFS driver ([linux-apfs-rw](https://github.com/linux-apfs/linux-apfs-rw)).
   - **Never `cp -a` existing iOS files** on the mounted disk. It corrupts compressed files.
6. **First boot and setup.** Go through Apple's welcome screens and tap **Agree** on the terms.
   - **Don't set a passcode, don't turn on Location Services**, and never use **Erase All Content and Settings**
     (that last one bricks the install).
7. **Optional extras** (guide pages "Reverse Tethering" and "Jailbreak Utility Bootstrap"):
   - Reverse tethering gives the phone internet through the companion VM. All of the network setup happens inside
     the companion; your PC's own network isn't changed.
   - The bootstrap gives you a root shell and `apt`.

**Take a disk snapshot after each stage that works**, so you can roll back if something breaks later. Run it
while the emulator is off:

```
qemu-img snapshot -c after-setup root.qcow2      # save
qemu-img snapshot -l root.qcow2                  # list
qemu-img snapshot -a after-setup root.qcow2      # roll back
```

### Using it

Start it with `run-iphone.sh`, or with `run-iphone.sh --companion` if you want internet. With the package, the same
launcher is installed as `qemu-apple-t8030` (`qemu-apple-t8030 --help` lists its options). It reads your machine
settings from `~/.local/share/qemu-apple-t8030/vm-args.sh`; copy
`/usr/share/doc/qemu-apple-t8030-git/vm-args.example.sh` there and change the file names to yours. The helper VM
for internet isn't part of the package: `--companion` starts your own `companion.sh` from that folder.
- The window opens at 0.65× size (about 85% of a 1440p screen tall), centred, with sharp text.
- Use View → Zoom in the window's menu to change the size.
- Boot takes about 2.5 minutes. The first picture you see is the boot splash. `tools/set-boot-splash.sh`
  (`qemu-apple-t8030-set-boot-splash` in the package) swaps it for any picture you like, or for your GitHub avatar.

| Input | iPhone button |
|---|---|
| Left click / drag | Finger tap / swipe and scroll |
| **F6** or **middle click** (needs `patches/0001-…`) | Home (press twice for the app switcher) |
| **F5** | Side / power button |
| **F3 / F4** | Volume down / up |
| Hold **F4**, then also hold **F5** | "Slide to power off" / Emergency SOS screen |
| **F1** | Force shutdown. **Only if it's frozen**; it's like pulling the battery |

The first key press or two after boot can be ignored (upstream issue #247), so press again.

**To shut down safely:** in iOS, go to **Settings → General → Shut Down** and drag the slider. Wait about 15
seconds after the screen goes black, then close the window. Closing the window while iOS is running can damage
its disk.

**Installing your own apps:** see "Root shell, internet, apt and app installs" in the iPhone README. In short, a
self-built `.app`, fake-signed with `ldid`, is copied to `/Applications` and registered with `uicache`.
`testapp/` builds a tiny UIKit app on Linux with **no Apple SDK**.

**What doesn't work:**
- The App Store and Apple ID / iCloud sign-in. This isn't a real Apple device.
- Wi-Fi in Settings. There's no Wi-Fi chip; internet comes over the USB link instead.
- Phone calls, the cameras and Face ID.
- A "back" swipe from the screen edge (iOS ignores edge gestures in this build).

---

## 5. Setting up the iPod touch 1G (the quick one)

1. Install the `qemu-ios-ipod-git` package (section 3), or build devos50's `qemu-ios` (branch `ipod_touch_1g`)
   yourself with **gcc**.
2. Download the four system files from the project's own release `n45ap_v1`. The sha256 checksums are in
   [`ipod-touch-1g/README.md`](ipod-touch-1g/README.md). With the package, put them in `~/.local/share/qemu-ios-ipod/`
   and leave `nand_n45ap.zip` zipped.
3. Run `ipod-touch-qemu` (package) or `run-ipod.sh` (your own build).
   - It unpacks the NAND into RAM, because the image is about 133,000 tiny files and that's painfully slow on a
     hard drive.
   - It forces native Wayland.
   - It sets Auto-Lock to Never on each boot.

**Controls:** the mouse is your finger, **H** = Home, hold **P** for about 5 s to power off. **Don't short-press P**:
the device never wakes from sleep. Changes aren't kept between boots; that's how the emulator works.

---

## 6. Setting up the iOS 12 shell

This is for people who want to poke at iOS from a terminal. It never shows a home screen.
1. Install the `xnu-qemu-arm64-git` package (section 3; the Linux patches are already in it), or build Aleph's
   `xnu-qemu-arm64` yourself **with the patches in [`ios12-xnu-qemu/patches/`](ios12-xnu-qemu/patches/)**.
   They fix the networking layer for a Linux host and the console display format.
2. Follow Aleph's own instructions to prepare the iOS 12.1 files. [`ios12-xnu-qemu/README.md`](ios12-xnu-qemu/README.md)
   lists the Linux replacements for the guide's macOS-only steps. With the package, put the five finished files in
   `~/.local/share/xnu-qemu-arm64/`.
3. `xnu-qemu-ios` (package) or `run-ios.sh` shows the kernel console in a window; this terminal is the keyboard.
   `xnu-qemu-ios-ssh` or `ssh-ios.sh` connects over SSH through the tunnel that `tunnel-linux/` cross-builds without
   Xcode (the package installs that source in `/usr/share/doc/xnu-qemu-arm64-git/tunnel-linux/`).

---

## 7. Troubleshooting

| What you see | Likely cause | Fix |
|---|---|---|
| iPhone window is taller than the screen | old launcher with `zoom-to-fit=on` | use this repo's `run-iphone.sh` (scale 0.65) or View → Zoom Out |
| Restore stuck at "ASR 4%" | started with `-display none` | use `-display egl-headless` |
| Restore fails with "zero-length ART" | built without debug info | rebuild with `-Ddebug=true` |
| Restore fails partway, "Unable to send data to ASR" | companion short on RAM, or host too busy | give the companion 8 GB, close heavy apps, retry from a clean disk |
| Stuck on the Apple logo after restore | simulated SEP | redo with the real-SEP setup |
| Keys do nothing right after boot | upstream #247 | press F3 or F4 once, then try again |
| "Swipe up" setup screen won't respond | known quirk | hold F4 then F5, slide to power off, boot again |
| Phone has no internet | started without `--companion`, or tethering not set up | start with `--companion`; see guide page "Reverse Tethering" |
| iPod screen frozen black | it went to sleep | close the window and relaunch (it can't wake) |
| A package command says files are missing | nothing set up yet, or files in the wrong folder | put them in the folder it names (see section 3); `--help` shows the options |
| `qemu-apple-t8030`: "No VM set up yet" | `data/` or `vm-args.sh` missing in `~/.local/share/qemu-apple-t8030/` | copy `vm-args.example.sh` there and fix the file names, or set `QEMU_T8030_DIR` to your existing folder |
| Building the iPhone package fails: `lzfse` not found | it's only in the AUR | install `lzfse` from the AUR first (an AUR helper does this for you) |
| `pacman -U` says the file is corrupted | incomplete download | download it again and check it with `sha256sum -c SHA256SUMS --ignore-missing` |
| Menu entry starts but nothing appears | the launcher stopped with a message you can't see | run the command in a terminal to read the message |
| iPod window never appears on X11 | SDL hang on X11 (sdl2-compat) | use a Wayland session; the launcher picks Wayland automatically when it's there |

---

## 8. Glossary

- **QEMU:** the open-source program that pretends to be a whole computer (here, an iPhone or iPod).
- **IPSW:** Apple's iOS firmware file, the same one iTunes or Finder uses to restore a real iPhone.
- **SEP (Secure Enclave Processor):** the iPhone's separate security chip. It handles passcodes and encryption keys.
- **Companion VM:** a small Linux virtual machine connected to the emulated iPhone by a virtual USB cable. It's used
  to restore iOS, and later to share internet with the phone.
- **Restore:** installing iOS onto the emulated phone's empty disk, like a factory reset from a computer.
- **Reverse tethering:** the phone gets internet from the computer it's plugged into, the opposite of a phone hotspot.
- **Bootstrap:** a bundle of command-line tools (bash, apt) added to iOS so you get a terminal and a package manager.
- **Fake-signing (`ldid -S`):** adding a placeholder signature to an app. The emulator's patched kernel accepts it.
- **TCG:** QEMU's software CPU emulation. It's what makes the iPhone slow to boot, because there's no hardware shortcut.
- **qcow2 snapshot:** a saved point inside the iPhone's disk file that you can roll back to.
- **Splash:** the picture shown on screen before iOS starts drawing.
- **Package (`.pkg.tar.zst`):** a ready-to-install bundle for Arch Linux's package manager, `pacman`.
- **AUR (Arch User Repository):** a community collection of build recipes for Arch. An AUR helper like `yay`
  downloads the recipe and compiles the program on your PC.
- **PKGBUILD:** the build recipe inside an AUR package or in `packaging/arch/`.
- **`-git` package:** builds the newest code from the project's git repository at the time you install it.
- **SHA256SUMS:** a list of fingerprints for the release files, so you can check a download is complete and unchanged.
