# Installing VELCORA

This describes the current **0.1.0-dev** image.  It is a development image:
the live session and the installer start, but a complete disk installation
has not been verified end to end yet.  Test in a virtual machine first.

## 1. Choose an image

Velcora provides two amd64 images, like Kali's Live and Installer downloads:

- **Live** — boots into the Xfce desktop so you can try Velcora. Calamares is
  available from the desktop when you are ready to install.
- **Installer** — starts Debian Installer directly, with graphical and text
  installation choices. The software screen offers Debian's available
  desktops, with Xfce selected by default. The Velcora package set and Xfce
  are on the DVD; other desktop choices may need a network connection.

Build both from source with the development instructions
([development](../development/README.md), `build/README.md`):

```sh
make iso
```

The release script checks the ISO size and publishes it as one file when it
fits GitHub's 2 GiB asset limit, or splits it into parts when it does not.
Release checksums cover the ISO and, when split, each part:

```sh
sha256sum -c velcora-0.1.0-dev-live-amd64.iso.sha256
sha256sum -c velcora-0.1.0-dev-installer-amd64.iso.sha256
```

## 2. Boot it

**Virtual machine** (VirtualBox or QEMU): give it at least 4 GB RAM and
2 CPUs, attach the ISO to the optical drive, and boot.  Both BIOS and UEFI
boot work.  VirtualBox notes, including Guest Additions, are in
`build/README.md`.

The Live boot menu offers:

- **Try Velcora Linux (live demo)** — the default.  Starts the live session
  and writes nothing to disk.

**USB stick**: write the ISO directly, not as a file copy.

```sh
# replace /dev/sdX with the stick; this erases the whole device
sudo dd if=velcora-0.1.0-dev-live-amd64.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

GNOME Disks and Ventoy also work.  The image is hybrid, so the same stick
boots on BIOS and UEFI machines.

If the firmware refuses to start the live media, disable Secure Boot in the
firmware settings.  Secure Boot has not been tested with the live image.

## 3. Live session

- The boot menu's **Try Velcora Linux** entry opens the live demo.  A
  welcome window explains that nothing is written to disk and offers
  **Try Velcora** and **Install Velcora**; closing it leaves you in the
  demo.  The window appears on every boot of the live media, including
  after a restart, because the session is not persistent.
- The live user is `velcora`; the live password is `velcora`. These public
  development credentials are not secure production credentials. The session
  logs in automatically.
- The live user has **passwordless** sudo.  This exists only in the live
  session.
- The live session runs from RAM: changes are lost at reboot.
- Interface translations ship for English, German, French, Spanish, Italian,
  Portuguese, Dutch, Polish, Russian, Simplified and Traditional Chinese,
  Japanese, Korean, Turkish and Arabic.  Other languages fall back to
  English.
- `sudo -v` should succeed without a prompt; `ansible --version`,
  `aws --version`, `az version` and `kubectl version --client` are the
  quickest check that the cloud tooling is present.

## 4. Install to disk

For the Live image, click **Install Velcora** in the welcome window, use the
desktop icon, or run
`velcora-installer` from a terminal opened inside the live Xfce desktop.
Calamares is graphical and cannot be launched from a text-only console. It
starts with root privileges through the live session's passwordless sudo.

For the Installer image, boot it and follow Debian Installer's prompts. It
offers graphical and text modes and leaves disk, language, keyboard and user
choices interactive. The software screen defaults to Xfce and lets you select
another Debian desktop task. The additional desktop packages are downloaded
from the configured Debian mirror.

Calamares asks for language, keyboard, disk layout, users and a summary
before writing anything.  Installing replaces the target disk's contents.
The default Calamares partitioning options apply, including its optional
LUKS encryption.

At the end of the installation a chroot step removes
`/etc/sudoers.d/90-velcora-live` from the target, so the installed system has
no passwordless sudo and no automatically created live account. The user you
create during installation gets password-protected sudo through the `sudo`
group.

## 5. After installing

- Remove the installation medium and boot from the disk.
- Check `sudo -v` asks for your password: passwordless sudo must be gone.
- Enable the firewall if you want it: `sudo ufw enable` (installed, off by
  default).
- Install updates with `sudo apt update && sudo apt upgrade`.
- Open **Velcora Tweaks** from the applications menu to install another
  desktop environment, update the system or run the VirtualBox helper.

## Known limitations

- A full install to disk has not been run end to end by the maintainer.
- Secure Boot, encryption and dual-boot have not been tested.
- There are no VELCORA package repositories yet; the installed system uses
  Debian's mirrors.
- The live image's cloud tools are the Debian-packaged versions only; see
  `cloud/README.md`.

Report problems with the details requested in `SUPPORT.md`.
