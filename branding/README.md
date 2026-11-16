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
- `fonts/inter/`: the UI typeface.  The variable and italic faces are staged
  to `/usr/share/fonts/truetype/velcora/` and selected by fontconfig, GTK and
  Xsettings.
- `fonts/jetbrains-mono/`: the terminal typeface only.  The ligature faces in
  `ttf/` (`JetBrainsMono-*.ttf`) are staged for `xfce4-terminal`, together
  with `OFL.txt`, `AUTHORS.txt` and `README.md` under
  `/usr/share/doc/fonts-jetbrains-mono-velcora/`.  The `NL` (no-ligature)
  family, `variable/` and `webfonts/` are source material and are not
  installed.
- `colours/`: the VELCORA palette.  `palette.json` and `palette.css` are the
  reference values; the boot renderer still hardcodes the same midnight and
  blue tokens.

Rendered output goes to `build/generated/` and is not committed.
