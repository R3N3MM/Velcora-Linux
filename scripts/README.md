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
- `release/publish-iso.sh`: splits and publishes the ISO on GitHub releases.

`make validate` runs the static checks; `make iso` runs everything above.
