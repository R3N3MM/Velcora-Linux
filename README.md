# VELCORA Linux

VELCORA is a Debian-based Linux distribution focused on Cloud
Administration.

- **Base:** Debian 13 (trixie), amd64, built with live-build.
- **Image:** hybrid BIOS/UEFI ISO with branded isolinux and GRUB menus and a
  Plymouth boot theme.
- **Desktop:** Xfce with LightDM.  Inter is the UI typeface; JetBrains Mono
  is used only by `xfce4-terminal`.
- **Installer:** Calamares, started from the live desktop by
  **Install Velcora**.
- **Cloud tooling:** `ansible`, `awscli`, `azure-cli`, `kubernetes-client`,
  `python3`, `git`, `openssh-client` and `yq` from Debian trixie.

## Project status

Development: **0.1.0-dev**.  This is a development image, not a stable
release.  The live image boots on BIOS and UEFI, reaches the Xfce desktop and
starts the installer; a complete installation to disk has not been verified
end to end.  See [CHANGELOG.md](CHANGELOG.md) for what is in the image and
what is still missing.

## Download and try it

Prebuilt live ISOs are published on the
[releases page](https://github.com/R3N3MM/Velcora-Linux/releases).

GitHub caps a release asset at 2 GiB, so each ISO is split into parts.
Download the parts, join them, and verify the checksum:

```sh
cat velcora-0.1.0-dev-amd64.iso.part* > velcora-0.1.0-dev-amd64.iso
sha256sum -c velcora-0.1.0-dev-amd64.iso.sha256
```

Then boot it in a virtual machine or write it to a USB stick.  Step-by-step
instructions, live-session credentials and known limitations are in
[documentation/installation/README.md](documentation/installation/README.md).
VirtualBox notes are in
[build/README.md](build/README.md#running-in-oracle-virtualbox).

## Build from source

Requirements: Docker, make, bash and 15 GiB free disk.  The build runs inside
`debian:trixie`, so no Debian build tools are needed on the host.

```sh
make validate   # static configuration checks, seconds
make iso        # 20–40 minutes on a first build, ~2 GB download
make test       # branding, ISO structure, checksum, package lists
make test-boot  # headless BIOS and UEFI QEMU smoke test
```

The ISO and its checksum are written to `build/output/`.  Details are in
[build/README.md](build/README.md),
[testing/README.md](testing/README.md) and
[documentation/development/README.md](documentation/development/README.md).

## Repository structure

- `branding/` — logo, wallpapers, icons, fonts and palette; rendered into
  the image at build time.
- `boot/` — bootloader menus, Plymouth theme and boot hooks.
- `build/` — live-build configuration, build output locations and the ISO
  build documentation.
- `debian/` — os-release, Calamares, apt pins, package lists, hooks and
  live-session sudoers.
- `desktop/` — Xfce, LightDM, GTK and font configuration.
- `documentation/` — installation and development guides; the remaining
  guides are placeholders.
- `packages/` — placeholder categories; the packages actually installed are
  in `debian/package-lists/`.
- `cloud/` — placeholder cloud-administration domains and notes on tools
  Debian does not package.
- `infrastructure/` — placeholder system, hardening and networking material.
- `repository/` — placeholder repository and governance material; releases
  are GitHub release assets, not an APT repository.
- `scripts/` — build, validation, release and maintenance scripts.
- `testing/` — headless boot smoke test; other test categories are empty.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the workflow, commit format and
review expectations.  Security reports go through
[SECURITY.md](SECURITY.md); behaviour expectations are in
[CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## Licence

VELCORA's own scripts, configuration and documentation are released under
the MIT licence in [LICENSE](LICENSE).  Third-party packages, the bundled
fonts and the Velcora branding keep their own terms, which `LICENSE` also
notes.
