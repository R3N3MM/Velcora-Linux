# Desktop

Xfce and LightDM configuration, stored with the image paths it targets and
staged into `build/work/live-build/config/includes.chroot/` at build time.

- `xfce/etc/xdg/` and `xfce/etc/skel/`: desktop wallpaper and Xsettings for
  every user and for the live user's skeleton.  Xsettings selects the
  `Velcora` icon theme and the bundled Inter typeface.
- `xfce/.../xfce4-terminal.xml`: the `xfce4-terminal` xfconf channel.  It
  selects `JetBrains Mono 11` with `font-use-system` disabled, so only the
  terminal uses the monospace face; Xsettings, GTK and LightDM keep Inter.
  `terminalrc` is legacy and is not written.
- `lightdm/`: a drop-in for `lightdm-gtk-greeter` using the default
  wallpaper, the Velcora icon theme and the rendered whale logo.
- `gtk-3.0/`: GTK icon theme and font defaults for non-Xfce GTK tools.
- `fonts/`: fontconfig preference for Inter Variable; the font binaries are
  staged from `branding/fonts/inter/`.
- `autostart/`: the live-only helpers: the welcome window that offers
  **Try Velcora** or **Install Velcora**, and the installer icon on the
  desktop.  Both check for the live session and do nothing after a disk
  install.

All eight wallpapers in `branding/wallpapers/` are installed; the default is
`velcora_wallpaper_datacenter_core.jpg` through the
`/usr/share/backgrounds/velcora/velcora-default.jpg` symlink.
