# VELCORA build system

Status: **phase 3 — branded ISO with a Calamares installer.** BIOS and UEFI
boot reach the branded Xfce desktop, VirtualBox guest tools are preinstalled,
and **Install Velcora** launches Calamares from the live desktop. An
end-to-end disk installation still needs a test pass.

## Decisions

- **Base:** Debian 13 (trixie), amd64 only.
- **Image:** live-build `iso-hybrid` (BIOS and UEFI) with Calamares.
- **Desktop:** Xfce via `task-xfce-desktop`, LightDM with autologin.
- **Branding:** Velcora ISO metadata and boot menus, `os-release`, a default
  wallpaper for new users, and Calamares branding derived from
  `calamares-settings-debian`.
- **Root filesystem:** single xz-compressed squashfs.
- **Build isolation:** the ISO is built inside `debian:trixie` in Docker
  with `--privileged`, so the host needs no build dependencies.
- **Packages:** split into desktop, system, cloud, VM and installer lists
  under `live-build/config/package-lists/`. Kubernetes Helm is not packaged
  in Debian (the `helm` package is Emacs Helm), so it will be added from the
  upstream repository in the cloud-tooling phase.
- **VirtualBox:** Debian 13 no longer ships `virtualbox-guest-utils` or
  `virtualbox-guest-x11` in stable. The two userspace packages are pinned
  from unstable/contrib at build time (`config/archives/velcora-contrib.*`);
  the source and pin are removed before the image is created. They use the
  kernel's in-tree `vboxguest`/`vboxsf`/`vboxvideo` modules. The host's
  Guest Additions disc remains available as an update path. See
  *Running in VirtualBox* below.

## Layout

The top-level areas are the source of truth.  `build/` only assembles them
into a live-build tree, which keeps the boot, desktop and Debian
configuration reviewable in the place the repository structure says they
belong.

```text
boot/
  bootloaders/                   isolinux and GRUB menus/theme
  plymouth/velcora/              Plymouth theme description and script
  hooks/                         Plymouth selection/initramfs hook
debian/
  base/                          os-release, issue, issue.net
  installer/                     Calamares settings, branding and launchers
  vm/                            VirtualBox Guest Additions helper
  apt/, archives/                apt retry settings and build-only pins
  package-lists/                 package selections (*.list.chroot)
  hooks/                         chroot cleanup for installer branding
  sudoers/                       live-only passwordless sudo
desktop/
  xfce/                          Xfce desktop and per-user defaults
  lightdm/                       LightDM greeter branding
  gtk-3.0/, fonts/               GTK settings and Inter font preference
  autostart/                     live-only installer launcher
branding/
  logo/, wallpapers/, icons/     source artwork rendered into the image
build/
  live-build/auto/config         lb config options and ISO metadata
  generated/                     rendered artwork (ignored)
  work/                          scratch copy used by the builder (ignored)
  output/                        ISO, checksum and build log (ignored)
scripts/build/
  build-iso.sh                   render, stage, then run lb config + lb build
  stage-live-config.sh           compose live-build config from the sources
  render-boot-branding.py        splash, Plymouth frames, logo images
  sync-branding-assets.py        wallpapers and the Velcora icon theme
  validate-config.sh             static checks, used by CI and make
```

`make iso` renders `branding/` into `build/generated/`, stages the source
areas into `build/work/live-build/config/`, and then runs live-build.  The
rendered files are build artefacts, so they are not committed.

## Building

Requirements: Docker, make, bash, 15 GiB free disk.

```sh
make validate   # fast; checks scripts, lists and version
make iso        # 20–40 minutes on a first build, ~2 GB download
```

A full build fetches well over a gigabyte, so apt retries transient DNS and
connection failures instead of aborting (`config/apt/apt.conf` in the image,
`/etc/apt/apt.conf.d/90retries` in the builder container).

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

## Publishing a release

GitHub caps each release asset at 2 GiB, and the ISO is slightly larger, so
the release script splits it into two parts, writes checksums and publishes
them with join instructions:

```sh
make publish              # publish the ISO in build/output/
scripts/release/publish-iso.sh --dry-run   # stage and print, upload nothing
```

`REPO`, `TAG` and `PART_SIZE` can be overridden in the environment. The tag
defaults to `v<version>` (for example `v0.1.0-dev`) and the release is marked
as a pre-release. Parts and notes are staged in `build/output/release/`.

## Live session defaults

- User: `velcora`, password: `live`, groups include `sudo`.
- Hostname: `velcora`; LightDM logs the user in automatically.
- The live user has passwordless sudo. Calamares removes
  `/etc/sudoers.d/90-velcora-live` from the installed system; installed
  users get normal password-protected sudo through the `sudo` group.
- **Install Velcora** is added to the live desktop at login. The icon is
  deliberately live-only, so installed systems do not inherit it.
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
resizing. The image preinstalls the `virtualbox-guest-utils` and
`virtualbox-guest-x11` userspace packages; Debian's kernel already provides
the matching `vboxguest`, `vboxsf` and `vboxvideo` modules, so these work in
the live session without any manual step.

If the host's VirtualBox is newer than the guest tools in the image, update
them from the host's own disc:

1. In the VM window choose **Devices → Insert Guest Additions CD image**.
2. Open a terminal and run:

   ```sh
   sudo velcora-install-guest-additions
   ```

3. Log out and back in, or run `sudo systemctl restart lightdm`, so the new
   input and video drivers load.

The command mounts the disc, builds any modules it needs against the running
kernel and loads them. The image contains `build-essential`, `dkms`,
`perl`, `bzip2` and `linux-headers-amd64` for that purpose; the disc comes
from the VirtualBox installation on the host, which keeps Guest Additions
matched to the VirtualBox version in use.

Guest Additions 7.2.22 does not compile its optional `vboxvideo` driver
against the Debian 13 kernel, so the installer may print a build failure for
that module. Clipboard sharing, shared folders and VMSVGA display resizing
come from `vboxguest` and `vboxsf`, which build and load normally, and the
kernel's own `vboxvideo` driver remains available, so the failure is
harmless.

The live session runs from RAM, so changes are lost at reboot. Use
**Install Velcora** to install onto disk when you need persistence.

## Verified build

| Field | Value |
| --- | --- |
| Date | 2026-11-15 |
| Version | 0.1.0-dev |
| Source commit | `28f96ee` |
| Size | 2,227,011,584 bytes (2.1 GiB) |
| SHA-256 | `507d6b3644d0cd04e9abf54d4a5bffdb6005bb14d33bfd0d5d487fb97dc5cf78` |
| Boot | BIOS and UEFI (QEMU/KVM, OVMF) |

Verified in the live session:

- BIOS and UEFI boot both reach the Xfce desktop with no keypress, after
  the 30-second boot-menu timeout.
- LightDM autologin as `velcora`, Xfce panel and terminal working.
- `sudo` accepts the `live` password; `velcora` is in the `sudo` group.
- VirtualBox Guest Additions 7.2.22: `velcora-install-guest-additions`
  found the mounted host disc and built `vboxguest` and `vboxsf` for
  `6.12.117+deb13-amd64`; the helper reports that the modules load
  automatically under VirtualBox.
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
2. ISO build, boot test and VM integration (VirtualBox Guest Additions). **(done)**
3. Branding integration — fonts, palette, wallpapers, LightDM, Plymouth.
4. Installer and disk installation.
5. Cloud tooling, repositories, updates and hardening.
6. CI image builds, signing and release automation.
