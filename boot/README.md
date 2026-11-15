# Boot

Bootloader, Plymouth and initramfs configuration.  These files are staged
into `build/work/live-build/config/` by
`scripts/build/stage-live-config.sh`; live-build itself is not edited here.

- `bootloaders/isolinux/`: BIOS menu, entries and colours.
- `bootloaders/grub-pc/`: UEFI GRUB entries, theme and timeout.
- `plymouth/velcora/`: `velcora.plymouth` and `velcora.script`, the animated
  boot theme.  The PNG frame sequence and `background.png` are rendered
  from `branding/logo/velcora-logo.svg` at build time.
- `hooks/0100-velcora-branding.hook.chroot`: selects the Velcora Plymouth
  theme and rebuilds all initramfs images so the splash works on BIOS and
  UEFI.

The boot-menu splash is rendered to `build/generated/bootloaders/splash.svg`
because firmware menus cannot animate SVG.
