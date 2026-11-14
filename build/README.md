# VELCORA build system

Status: **phase 1 — build foundation.** The live-build configuration and
build runner exist; the first ISO has not been built or boot-tested yet.

## Decisions

- **Base:** Debian 13 (trixie), amd64 only.
- **Image:** live-build `iso-hybrid` (BIOS and UEFI), no installer yet.
- **Desktop:** Xfce via `task-xfce-desktop`, LightDM with autologin.
- **Root filesystem:** single xz-compressed squashfs.
- **Build isolation:** the ISO is built inside `debian:trixie` in Docker
  with `--privileged`, so the host needs no build dependencies.
- **Packages:** split into desktop, system and cloud lists under
  `live-build/config/package-lists/`. Only packages available in Debian 13
  are listed; third-party repositories come later. Kubernetes Helm is not
  packaged in Debian (the `helm` package is Emacs Helm), so it will be
  added from the upstream repository in the cloud-tooling phase.

## Layout

```text
build/
  live-build/
    auto/config                  lb config options
    config/package-lists/        package selections (*.list.chroot)
  work/                          scratch copy used by the builder (ignored)
  output/                        ISO, checksum and build log (ignored)
scripts/build/
  build-iso.sh                   containerised lb config + lb build
  validate-config.sh             static checks, used by CI and make
```

## Building

Requirements: Docker, make, bash, 15 GiB free disk.

```sh
make validate   # fast; checks scripts, lists and version
make iso        # 20–40 minutes on a first build, ~2 GB download
```

The result is written to:

```text
build/output/velcora-<version>-amd64.iso
build/output/velcora-<version>-amd64.iso.sha256
build/output/build.log
```

`VELCORA_BUILDER_IMAGE` overrides the build image and `VELCORA_MIN_FREE_GIB`
the disk-space check. `make clean` removes `work/` and `output/`.

If `make iso` fails, the container log is on screen and in
`build/output/build.log`; the live-build tree is preserved in
`build/work/live-build`.

## Live session defaults

- User: `velcora`, password: `live`, groups include `sudo`.
- Hostname: `velcora`; LightDM logs the user in automatically.
- Root login and the root password are not enabled.

These defaults are for development images only and will change before a
public release.

## Testing an image

Boot in a VM:

```sh
qemu-system-x86_64 -m 4096 -smp 2 -enable-kvm \
  -cdrom build/output/velcora-<version>-amd64.iso
```

Or write it to a USB stick with `dd`, GNOME Disks or Ventoy. Test both
BIOS and UEFI boot paths where the hardware allows it.

Minimum smoke test for the first image:

1. GRUB/syslinux menu appears and the live session reaches LightDM.
2. Desktop logs in as `velcora`, panel and terminal work.
3. `sudo -v`, `ansible --version`, `aws --version`, `az version`,
   `kubectl version --client` succeed.
4. NetworkManager connects over Ethernet and Wi-Fi.
5. Shutdown and reboot work cleanly.

## Phases

1. Build foundation — configuration, runner, validation. **(done)**
2. First ISO build and boot test in a VM.
3. Branding integration — fonts, palette, wallpapers, LightDM, Plymouth.
4. Installer and disk installation.
5. Cloud tooling, repositories, updates and hardening.
6. CI image builds, signing and release automation.
