# Debian integration

Debian-specific pieces of the image, staged into the live-build tree rather
than kept under `build/`.

- `base/`: `os-release`, `issue` and `issue.net`; `/usr/lib/os-release` is a
  relative symlink to `/etc/os-release`.
- `installer/`: Calamares settings, module configuration, Velcora branding,
  and the live **Install Velcora** launcher.  `calamares-settings-debian`
  provides the base; its Debian branding is removed by a hook.
- `vm/`: the on-demand VirtualBox Guest Additions helper.
- `apt/`: retry and timeout settings used while building.
- `archives/`: build-only sources and pins for the VirtualBox guest tools
  from unstable/contrib; live-build removes them before the image is made.
- `package-lists/`: desktop, system, cloud, VM and installer package sets.
- `hooks/`: chroot cleanup that removes Debian's installer branding.
- `sudoers/`: live-only passwordless sudo, which Calamares deletes from an
  installed system.
