# Packaging

`arch/` holds the Arch Linux packages, one folder each, exactly as they are on the AUR:

| Folder | AUR | What |
|---|---|---|
| `arch/qemu-apple-t8030-git/` | [qemu-apple-t8030-git](https://aur.archlinux.org/packages/qemu-apple-t8030-git) | iPhone 11 (t8030), unofficial build of [Inferno](https://github.com/ChefKissInc/Inferno) |
| `arch/qemu-ios-ipod-git/` | [qemu-ios-ipod-git](https://aur.archlinux.org/packages/qemu-ios-ipod-git) | iPod touch 1G, [devos50/qemu-ios](https://github.com/devos50/qemu-ios) |
| `arch/xnu-qemu-arm64-git/` | [xnu-qemu-arm64-git](https://aur.archlinux.org/packages/xnu-qemu-arm64-git) | iOS 12.1 shell, [alephsecurity/xnu-qemu-arm64](https://github.com/alephsecurity/xnu-qemu-arm64) + Linux-host patch |

None of them contain or download Apple files. Each installs under `/opt/<name>` so it never clashes with the
system `qemu`.

## Building and testing in a clean container

`arch/container.sh` (needs docker or podman) is what the GitHub Actions release workflow runs:

    packaging/arch/container.sh build qemu-ios-ipod-git out/    # fresh archlinux:base-devel, makepkg -s, namcap
    packaging/arch/container.sh test out/                       # install all three in another fresh container and check them

The test only starts each emulator with `--version` and `-machine help`, checks the launchers stop with their
"files missing" message, and checks every binary finds its libraries. It never boots anything.
`JOBS=8` limits parallel compile jobs; `SRCDEST=dir` keeps the git clones between runs.

## Making a release

1. Write `packaging/release-notes/vX.Y.md`.
   Also bump `_extras_tag` in `arch/xnu-qemu-arm64-git/PKGBUILD` to the new tag (that package takes its docs and
   the tcp-tunnel source from it) and regenerate its `.SRCINFO` (`makepkg --printsrcinfo > .SRCINFO`).
2. Commit, push, then `git tag vX.Y && git push origin vX.Y`.
3. The workflow `.github/workflows/release.yml` builds the three packages, tests them, and creates the release with
   the packages, their source tarballs and `SHA256SUMS`. If a release for that tag already exists it is not touched.
4. AUR: copy `PKGBUILD`, `.SRCINFO` and the package's other files into the AUR clone and push. The AUR copy is
   built by each user, so only change it when the PKGBUILD itself changes.
