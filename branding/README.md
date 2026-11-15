# Branding

Source artwork for VELCORA.  Nothing here is copied into the image by hand;
the build renders and stages it.

- `logo/velcora-logo.svg`: animated whale logo and the single source for the
  boot splash, Plymouth frames, greeter image, Calamares logo and installer
  icon.
- `wallpapers/`: eight unique wallpapers.  All are installed under
  `/usr/share/backgrounds/velcora/`; the datacenter-core image is the
  default through a relative symlink.  The `(1)` file is a duplicate and is
  intentionally skipped.
- `icons/panel/` and `icons/taskbar/`: source SVG/PNG glyphs for the
  `Velcora` icon theme, including freedesktop aliases for Xfce, browsers,
  terminals and status icons.
- `fonts/inter/`: bundled Inter variable fonts; `jetbrains-mono/` currently
  contains licence and documentation only.
- `colours/`: the VELCORA palette used by the boot menu and installer.

Rendered output goes to `build/generated/` and is not committed.
