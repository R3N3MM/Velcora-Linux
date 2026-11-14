# VELCORA build system

Status: **phase 2 — first ISO built and boot-tested.** BIOS and UEFI boot
both reach the Xfce desktop; boot-menu timeout and branding are the next
items.

## Decisions

- **Base:** Debian 13 (trixie), amd64 only.
- **Image:** live-build `iso-hybrid` (BIOS and UEFI), no installer yet.
- **Desktop:** Xfce via `task-xfce-desktop`, LightDM with autologin.
- **Root filesystem:** single xz-compressed squashfs.
- **Build isolation:** the ISO is built inside `debian:trixie` in Docker
  with `--privileged`, so the host needs no build dependencies.
- **Packages:** split into desktop, system, cloud and VM lists under
  `live-build/config/package-lists/`. Only packages available in Debian 13
  are listed; third-party repositories come later. Kubernetes Helm is not
  packaged in Debian (the `helm` package is Emacs Helm), so it will be
  added from the upstream repository in the cloud-tooling phase.
- **VirtualBox:** Debian 13 no longer ships `virtualbox-guest-utils`,
  `virtualbox-guest-x11` or `virtualbox-guest-dkms` in stable, so the image
  ships the build prerequisites instead and installs Guest Additions from
  the host's own "Insert Guest Additions CD image" disc. See
  *Running in VirtualBox* below.

## Layout

```text
build/
  live-build/
    auto/config                  lb config options
    config/package-lists/        package selections (*.list.chroot)
    config/bootloaders/          boot-menu timeout overrides
    config/includes.chroot/      files copied into the image
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

## Running in Oracle VirtualBox

Create a VM with type **Debian (64-bit)**, at least 4 GB RAM and 2 CPUs,
VMSVGA graphics and EFI enabled (the default in VirtualBox 7), then attach
`build/output/velcora-<version>-amd64.iso` to the optical drive and start
it. BIOS and EFI boot both work.

Guest Additions add clipboard sharing, shared folders and automatic
resizing. After the desktop appears:

1. In the VM window choose **Devices → Insert Guest Additions CD image**.
2. Open a terminal and run:

   ```sh
   sudo velcora-install-guest-additions
   ```

3. Log out and back in, or run `sudo systemctl restart lightdm`, so the new
   input and video drivers load.

The command mounts the disc, builds the modules against the running kernel
and loads them. The image already contains `build-essential`, `dkms`,
`perl`, `bzip2` and `linux-headers-amd64`; the disc comes from the
VirtualBox installation on the host, which keeps Guest Additions matched to
the VirtualBox version in use.

The live session runs from RAM. Guest Additions and any other changes are
lost at reboot until the installer phase adds persistent installation.

## Verified build

| Field | Value |
| --- | --- |
| Date | 2026-11-14 |
| Version | 0.1.0-dev |
| Source commit | `62fda30` |
| Size | 2,208,104,448 bytes (2.1 GiB) |
| SHA-256 | `fd10fee8568ab2798478daf26084faf7f24246fb508b10eb27f5ee5f00655c0e` |
| Boot | BIOS and UEFI (QEMU/KVM, OVMF) |

Verified in the live session:

- LightDM autologin as `velcora`, Xfce panel and terminal working.
- `sudo` accepts the `live` password; `velcora` is in the `sudo` group.
- `ansible 2.19.11`, `aws-cli 2.23.6`, `azure-cli 2.74.0`,
  `kubectl 1.32.3` all start and report their versions.
- HTTPS egress works (`curl -sI https://deb.debian.org` returns
  HTTP/2 200). ICMP echo is not forwarded by QEMU user networking, so
  the ping check in the smoke test is expected to fail in that VM only.
- Clean shutdown from the Xfce session.

Azure CLI prints Python 3.13 `SyntaxWarning`/`FutureWarning` noise and a
harmless `rdbms` module warning on first run; the command still works.

## Phases

1. Build foundation — configuration, runner, validation. **(done)**
2. First ISO build and boot test in a VM.
3. Branding integration — fonts, palette, wallpapers, LightDM, Plymouth.
4. Installer and disk installation.
5. Cloud tooling, repositories, updates and hardening.
6. CI image builds, signing and release automation.
