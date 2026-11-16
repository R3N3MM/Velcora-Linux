# Changelog

All notable changes to VELCORA Linux are recorded here.  The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); the project is not
yet at a stable release, so entries use the development version from
`VERSION`.

## [0.1.0-dev] - 2026-11-16

First development image.  Not a stable release; see *Known limitations*.

### Added

- Reproducible live-build pipeline for Debian 13 (trixie) amd64: `make iso`
  runs in a `debian:trixie` container and writes
  `build/output/velcora-0.1.0-dev-amd64.iso` plus a SHA-256 file and build
  log.
- Hybrid BIOS/UEFI image with branded isolinux and GRUB menus, a 30-second
  boot-menu timeout and a Plymouth theme rendered from
  `branding/logo/velcora-logo.svg`.
- Xfce desktop with LightDM, the `Velcora` icon theme, eight wallpapers, and
  Inter as the UI font.  `xfce4-terminal` uses JetBrains Mono 11 while every
  other application keeps Inter.
- Calamares installer started from the live desktop by **Install Velcora**;
  it removes the live-only passwordless sudo rule from the target system.
- VirtualBox guest userspace packages pinned from unstable/contrib and
  removed from the image after installation; on-demand Guest Additions
  helper for newer VirtualBox versions.
- Validation tooling: `make validate` (static configuration),
  `make lint` (shellcheck and Python), `make test` (branding assets, ISO
  structure, checksum, package resolution), `make checksum` and
  `make test-boot` (headless BIOS/UEFI QEMU smoke test).
- GitHub workflows: lint and package resolution on every push and pull
  request; ISO build, verification, artifact upload and split release assets
  on `v*` tags or manual dispatch.
- `scripts/maintenance/safe-commit.sh` with private-folder, size and
  home-path guards.
- Documentation for installing, building and testing the image; READMEs for
  every top-level folder.

### Verified

- The 2.1 GiB image built from commit `28f96ee` booted on BIOS and UEFI
  (QEMU/KVM with OVMF), reached LightDM and the Xfce desktop, ran
  `ansible`, `aws`, `az` and `kubectl`, and shut down cleanly.
- All 85 package-list entries resolve in Debian trixie.
- The terminal font selection was checked against `xfconf` in trixie: it
  reports `JetBrains Mono 11` with `font-use-system` false.

### Known limitations

- A complete installation to disk has not been executed end to end.
- Secure Boot, LUKS installation and dual boot are untested.
- The empty skeleton folders under `packages/`, `cloud/`, `infrastructure/`,
  `repository/`, the remaining `documentation/` guides and alternate build
  paths are not wired to the build.
- `branding/colours/palette.json` is not read by the renderer; the boot
  artwork hardcodes the same midnight and blue values.

[0.1.0-dev]: https://github.com/R3N3MM/Velcora-Linux/commits/main
