# VELCORA build system

Status: **0.1.0-dev — separate Live and Debian Installer images.** The Live
ISO boots into branded Xfce with Calamares available from the desktop. The
Installer ISO boots Debian Installer directly with Velcora's package profile.
Disk installation still needs an end-to-end test.

## Decisions

- **Base:** Debian 13 (trixie), amd64 only.
- **Images:** live-build hybrid Live ISO and Simple-CDD Debian Installer DVD,
  both for BIOS and UEFI.
- **Desktop:** Xfce via `task-xfce-desktop`, LightDM with autologin.
- **Branding:** Velcora ISO metadata and boot menus, `os-release`, a default
  wallpaper for new users, and Calamares branding derived from
  `calamares-settings-debian`.
- **Typefaces:** Inter Variable for the desktop and GTK applications;
  JetBrains Mono 11 for `xfce4-terminal` only, selected through the
  `xfce4-terminal` xfconf channel.
- **Root filesystem:** single xz-compressed squashfs.
- **Build isolation:** the ISO is built inside `debian:trixie` in Docker
  with `--privileged`, so the host needs no build dependencies.
- **Packages:** split into desktop, system, cloud, VM and installer lists
  under `debian/package-lists/`, plus seven cloud-administration category
  lists under `packages/<category>/`.  Staging copies both sets into the
  live-build tree, and validation rejects duplicates.  Kubernetes Helm is not
  packaged in Debian (the `helm` package is Emacs Helm) and is not installed;
  tools outside Debian main are skipped on purpose (see `cloud/README.md`).
- **VirtualBox:** Debian 13 no longer ships `virtualbox-guest-utils` or
  `virtualbox-guest-x11` in stable. The two userspace packages are pinned
  from unstable/contrib at build time (`debian/archives/velcora-contrib.*`);
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
  gtk-3.0/, fonts/               GTK settings and Inter UI font preference
  autostart/                     live-only installer launcher
packages/
  <category>/                    cloud-admin package lists, staged into the
                                 live-build package-lists/ directory
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
scripts/validation/              branding, ISO, checksum, package and lint checks
scripts/maintenance/             guarded commit helper
testing/boot/                    headless BIOS/UEFI QEMU smoke test
```

`make iso-live` renders branding and runs live-build. `make iso-installer`
creates a Simple-CDD profile from the same package lists, builds the local
Velcora branding package, then runs Debian Installer image tools. `make iso`
builds both images.

## Building

Requirements: Docker, make, bash, 25 GiB free disk for both images.

```sh
make validate   # fast; checks scripts, lists and version
make lint       # validate plus shellcheck and Python syntax
make iso        # build both image types; first build downloads several GB
make iso-live   # only the Live desktop ISO
make iso-installer # only the Debian Installer DVD
make test       # branding, ISO structure, checksum, package resolution
make test-boot  # headless BIOS and UEFI QEMU smoke test
```

A full build fetches well over a gigabyte, so apt retries transient DNS and
connection failures instead of aborting (`config/apt/apt.conf` in the image,
`/etc/apt/apt.conf.d/90retries` in the builder container).

The result is written to:

```text
build/output/velcora-<version>-live-amd64.iso
build/output/velcora-<version>-live-amd64.iso.sha256
build/output/velcora-<version>-installer-amd64.iso
build/output/velcora-<version>-installer-amd64.iso.sha256
build/output/build.log
```

`VELCORA_BUILDER_IMAGE` overrides the build image and `VELCORA_MIN_FREE_GIB`
the disk-space check. `make clean` removes `work/` and `output/`.

If `make iso` fails, the container log is on screen and in
`build/output/build.log`; the live-build tree is preserved in
`build/work/live` or `build/work/installer-cdd`.

## Publishing a release

GitHub caps each release asset at 2 GiB. The release script checks the ISO
size: it publishes one ISO when it fits, or splits a larger ISO into parts.
It writes checksums and join instructions when parts are needed:

```sh
make publish              # publish the ISO in build/output/
scripts/release/publish-iso.sh --dry-run   # stage and print, upload nothing
```

`REPO`, `TAG` and `PART_SIZE` can be overridden in the environment. The tag
defaults to `v<version>` (for example `v0.1.0-dev`) and the release is marked
as a pre-release. Parts and notes are staged in `build/output/release/`.

## Live session defaults

- User: `velcora`, password: `velcora`, groups include `sudo`. These public
  development credentials are not secure production credentials.
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

`make test` checks the ISO structure with `xorriso`, verifies its SHA-256 and
resolves the package lists.  `make test-boot` boots it headless in QEMU under
BIOS and UEFI and fails unless a login/desktop-looking frame appears twice in
a row; screenshots land in `build/output/boot-test-*.ppm`.  See
`testing/README.md` for options and requirements.

Boot manually in a VM:

```sh
qemu-system-x86_64 -m 4096 -smp 2 -enable-kvm \
  -cdrom build/output/velcora-<version>-live-amd64.iso
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
`build/output/velcora-<version>-live-amd64.iso` to the optical drive and start
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

## Earlier verified build (2026-11-15)

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
- `sudo` accepted the `live` password in that earlier image; `velcora` was
  in the `sudo` group. The current source configures `velcora` as the live
  password, but that change still needs an image boot check.
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

## Current ISO boot verification (2026-11-19)

The newly built `0.1.0-dev` ISO reached the Velcora Xfce desktop in a
disposable QEMU VM under both BIOS and UEFI. The marker was observed twice
per boot. The VM used software emulation and did not touch host disks. The
live-password hook is present in the staged image at
`/usr/lib/live/config/2000-velcora-password`; the published GitHub image is
still the earlier build listed above, with its historical `live` password.
The fresh image's interactive password prompt has not yet been confirmed.

Current image SHA-256: `4a0b2ce7ef866b704005f4e5d3dfac624a79740ccf31e9ddfcec5cc59844c549`.

`make test` passes on this image: configuration validation, shell/Python lint,
branding, hybrid ISO structure, checksum and all 12 package lists (140
packages resolved against Debian Trixie).

## Phases

1. Build foundation — configuration, runner, validation. **(done)**
2. ISO build, BIOS/UEFI boot test and VM integration (VirtualBox Guest
   Additions). **(done; fresh ISO boots in QEMU, Guest Additions were verified
   on the earlier build)**
3. Branding integration — fonts, wallpapers, LightDM, Plymouth, boot menus. **(done)**
4. Installer and disk installation.  Calamares and its configuration are in
   the image; an end-to-end disk install test is still open.
5. Cloud tooling, repositories, updates and hardening.  The Debian-packaged
   clients and the `packages/` category tooling are installed; tools outside
   trixie main are skipped by decision (see `cloud/README.md`), and no
   project package repository exists.
6. CI image builds, signing and release automation. Workflows and size-aware
   release publishing are written; the first tagged run and any signing are
   still open.
