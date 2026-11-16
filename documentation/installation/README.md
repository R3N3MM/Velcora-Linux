# Installing VELCORA

This describes the current **0.1.0-dev** image.  It is a development image:
the live session and the installer start, but a complete disk installation
has not been verified end to end yet.  Test in a virtual machine first.

## 1. Get the image

Prebuilt ISOs are attached to the
[GitHub releases](https://github.com/R3N3MM/Velcora-Linux/releases).  GitHub
caps a release asset at 2 GiB and the ISO is slightly larger, so it is
published in parts together with a checksum file:

```sh
cat velcora-0.1.0-dev-amd64.iso.part* > velcora-0.1.0-dev-amd64.iso
sha256sum -c velcora-0.1.0-dev-amd64.iso.sha256
```

You can also build it yourself; see
[development](../development/README.md) and `build/README.md`.

## 2. Boot it

**Virtual machine** (VirtualBox or QEMU): give it at least 4 GB RAM and
2 CPUs, attach the ISO to the optical drive, and boot.  Both BIOS and UEFI
boot work.  VirtualBox notes, including Guest Additions, are in
`build/README.md`.

**USB stick**: write the ISO directly, not as a file copy.

```sh
# replace /dev/sdX with the stick; this erases the whole device
sudo dd if=velcora-0.1.0-dev-amd64.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

GNOME Disks and Ventoy also work.  The image is hybrid, so the same stick
boots on BIOS and UEFI machines.

If the firmware refuses to start the live media, disable Secure Boot in the
firmware settings.  Secure Boot has not been tested with the live image.

## 3. Live session

- The live user is `velcora`; the live password is `live`.  The session logs
  in automatically.
- The live user has **passwordless** sudo.  This exists only in the live
  session.
- The live session runs from RAM: changes are lost at reboot.
- `sudo -v` should succeed without a prompt; `ansible --version`,
  `aws --version`, `az version` and `kubectl version --client` are the
  quickest check that the cloud tooling is present.

## 4. Install to disk

Start **Install Velcora** from the live desktop, or run `velcora-installer`
in a terminal.  It starts Calamares with root privileges through the live
session's passwordless sudo.

Calamares asks for language, keyboard, disk layout, users and a summary
before writing anything.  Installing replaces the target disk's contents.
The default Calamares partitioning options apply, including its optional
LUKS encryption.

At the end of the installation a chroot step removes
`/etc/sudoers.d/90-velcora-live` from the target, so the installed system has
no passwordless sudo and no `live` account.  The user you create during
installation gets password-protected sudo through the `sudo` group.

## 5. After installing

- Remove the installation medium and boot from the disk.
- Check `sudo -v` asks for your password: passwordless sudo must be gone.
- Enable the firewall if you want it: `sudo ufw enable` (installed, off by
  default).
- Install updates with `sudo apt update && sudo apt upgrade`.

## Known limitations

- A full install to disk has not been run end to end by the maintainer.
- Secure Boot, encryption and dual-boot have not been tested.
- There are no VELCORA package repositories yet; the installed system uses
  Debian's mirrors.
- The live image's cloud tools are the Debian-packaged versions only; see
  `cloud/README.md`.

Report problems with the details requested in `SUPPORT.md`.
