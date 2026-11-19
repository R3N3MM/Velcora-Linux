# Scripts

- `build/build-iso.sh`: containerised ISO build.  It renders branding,
  stages the top-level source areas into live-build, then runs `lb config`
  and `lb build`.
- `build/stage-live-config.sh`: composes the live-build configuration from
  `boot/`, `debian/`, `desktop/` and `branding/`.
- `build/render-boot-branding.py`: samples the animated logo into the boot
  splash, Plymouth frames and static logo images.
- `build/sync-branding-assets.py`: stages wallpapers and builds the
  `Velcora` icon theme.
- `build/validate-config.sh`: static source and composition checks.
- `validation/check-branding.sh`: required artwork, wallpapers, icon pairs
  and font licences.
- `validation/check-iso.sh`: hybrid BIOS/UEFI structure of a built ISO.
- `validation/checksum.sh`: verifies the ISO against its `.sha256`.
- `validation/check-packages.sh`: resolves every package-list entry in a
  `debian:trixie` container.
- `validation/lint.sh`: shellcheck and Python syntax checks.
- `release/publish-iso.sh`: publishes the ISO on GitHub releases, splitting it
  into parts only when it exceeds the per-asset limit.
- `maintenance/safe-commit.sh`: guarded commit and push helper.

`make validate` runs the static checks; `make lint` adds the linters;
`make iso` runs the build; `make test` and `make test-boot` check a built
image.
