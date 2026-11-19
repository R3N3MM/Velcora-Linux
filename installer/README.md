# Velcora Installer image

This tree builds the dedicated Debian Installer image, separately from the
live desktop image. Simple-CDD packages the Debian Installer, Velcora's
selected Debian package set, and a local branding package into a DVD image.

- `profiles/`: Simple-CDD package and preseed profiles.
- `branding-package/`: metadata and maintainer script for the local
  `velcora-branding` package. The build assembles its files from the shared
  `debian/`, `desktop/`, `boot/`, and `branding/` source trees.

The profile leaves locale, keyboard, user creation, and partitioning
interactive. Debian Installer's software step offers Debian's available
desktop tasks with Xfce selected by default. Alternative desktop tasks may
need a network connection during installation; Velcora branding and the
default Xfce package set are on the Installer DVD. The Velcora package
profile is selected automatically and LightDM is the display manager.
