# iPhone 11 (t8030) on QEMUAppleSilicon: work in progress

Goal: a modern iOS home screen with touch, and the ability to install apps, on a Linux host.

Current state (2026-10-24): QEMU is built and the official IPSW was downloaded from Apple. The restore runs from a
small helper Linux VM acting as the USB host, and the restore ramdisk reaches the Apple logo with its progress bar. Still being worked on: the restore stalling during ASR (filesystem copy), then the first normal boot to SpringBoard.

Scripts and notes will land here as they're proven.
