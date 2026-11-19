# Development

How to build, test and change VELCORA.  The image is Debian 13 (trixie) amd64,
built with live-build inside a `debian:trixie` container.

## Requirements

- Docker (the build and most checks run in containers)
- `make`, `bash`, `git`
- 25 GiB free disk and a network connection for both images
- Optional: `shellcheck`, `xorriso`, `qemu-system-x86`, `ovmf` for the checks
  and boot test on the host; each falls back to a container or is skipped
  with a clear error.

No live-build, debootstrap or Debian tooling is installed on the host.

## Commands

```sh
make help       # list targets
make validate   # static build-configuration checks (seconds)
make lint       # validate + shellcheck + Python syntax
make iso        # build the Live and Debian Installer images
make iso-live   # build only the Live desktop ISO
make iso-installer # build only the Debian Installer DVD
make test       # lint + branding + ISO structure + checksum + packages
make test-boot  # headless BIOS and UEFI QEMU smoke test
make checksum   # verify the ISO against its .sha256
make publish    # publish both images; oversized files are split into parts
make clean      # remove build/work and build/output
make distclean  # also remove in-tree live-build leftovers
```

`make test`, `make test-boot` and `make checksum` need an ISO in
`build/output/`.  `make iso` is the only step that needs Docker root
privileges inside the container; it is never run by CI on pull requests.

## Build pipeline

1. `scripts/build/build-iso.sh` starts the container and checks disk space.
2. `scripts/build/render-boot-branding.py` samples the animated logo into
   the boot-menu splash, Plymouth frames and static logo images under
   `build/generated/`.
3. `scripts/build/sync-branding-assets.py` stages wallpapers and builds the
   `Velcora` icon theme.
4. `scripts/build/stage-live-config.sh` copies `boot/`, `debian/`,
   `desktop/` and `branding/` fonts into `build/work/live-build/config/`.
5. `lb config` (from `build/live-build/auto/config`) and `lb build` produce
   `build/output/velcora-<version>-live-amd64.iso`, its `.sha256` and
   `build/output/build.log`.
6. `scripts/build/build-installer-iso.sh` builds the Simple-CDD profile and
   Debian Installer DVD with Velcora's selected package set and branding.

## Layout

- `boot/` — bootloader menus, Plymouth theme and hooks.
- `debian/` — os-release, Calamares, apt pins, package lists, hooks,
  sudoers.
- `desktop/` — Xfce, LightDM, GTK, fontconfig and autostart.
- `branding/` — logo, wallpapers, icons, fonts and palette.
- `build/live-build/auto/config` — live-build options and ISO metadata.
- `scripts/build/`, `scripts/validation/`, `scripts/release/`,
  `scripts/maintenance/` — build, checks, release and commit helpers.
- `packages/<category>/` — cloud-administration package lists.
- `testing/boot/` — headless boot smoke test.
- `cloud/`, `infrastructure/`, `repository/` — placeholders; see their
  READMEs.

## Changing things

- **Packages:** the base desktop/system/cloud-client/VM/installer sets live
  in `debian/package-lists/*.list.chroot`; cloud-administration tooling lives
  in `packages/<category>/velcora-<category>.list.chroot`.  Add a package to
  one of them (never both — validation rejects duplicates), then run
  `./scripts/validation/check-packages.sh` to confirm every name resolves in
  trixie.  Debian main/contrib only; third-party repositories are not used.
- **Desktop defaults:** edit the files under `desktop/`; they mirror their
  image paths.  `validate-config.sh` asserts the icon theme, the Inter UI
  font, the JetBrains Mono terminal font and the wallpaper.
- **Branding:** replace assets in `branding/`; do not hand-edit
  `build/generated/`.  `check-branding.sh` enforces the expected files.
- **Boot:** `boot/bootloaders/` and `boot/plymouth/velcora/`; run
  `make test-boot` afterwards.

## Before committing

```sh
make lint
scripts/maintenance/safe-commit.sh "type(scope): summary"
```

`safe-commit.sh` refuses to commit if a private folder is staged, a file is
larger than 5 MiB, or a staged text file contains the maintainer's home
path.  It then pushes to `origin main`; pass `--no-push` to commit locally.
Commit types are `feat`, `fix`, `docs`, `build` and `chore`, with a scope.

Never commit an ISO, `build/work/`, `build/generated/`, `build/live-build/cache/`
or `.build/`; `.gitignore` covers them.

## Tests and CI

- `scripts/validation/` — branding assets, checksum, hybrid-ISO structure,
  package resolution and lint.
- `testing/boot/boot-test.sh` — boots the ISO in QEMU with the QEMU monitor,
  screenshots it and fails if no login/desktop frame appears twice.  See
  `testing/README.md`.
- `.github/workflows/test.yml` and `package-check.yml` run lint and package
  resolution on every push and pull request.  `build.yml` builds and
  verifies the ISO only on `v*` tags or manual dispatch, uploads the ISO,
  checksum and log as an artifact and publishes the ISO as a release asset on
  tags (it is split into parts only if a future image exceeds the limit).  The
  first tagged run has not happened yet.

## Licence

VELCORA's own scripts, configuration and documentation are **MIT licensed**
(see `LICENSE`).  New files you add are covered by the same licence unless
they carry their own notice.  Do not copy code under an incompatible licence.
Third-party packages, fonts and the Velcora branding keep their own terms.
