# Package sets

Status: **placeholder.**  The category directories here are empty, and no
build step reads them.  The packages that actually go into the image are
listed in `debian/package-lists/*.list.chroot`.

## Where the packages live today

| List | Contents |
| --- | --- |
| `velcora-desktop.list.chroot` | Xfce, LightDM, NetworkManager, Xorg, Thunar, terminal, browser, desktop utilities. |
| `velcora-system.list.chroot` | sudo, curl, certificates, editors, tmux, htop, jq, ufw, Plymouth, DejaVu fonts. |
| `velcora-cloud.list.chroot` | ansible, awscli, azure-cli, kubernetes-client, python3 and its common modules, git, yq. |
| `velcora-installer.list.chroot` | Calamares, GRUB/shim/efibootmgr, filesystem and live-medium helpers. |
| `velcora-vm.list.chroot` | VirtualBox guest userspace tools, Guest Additions build prerequisites, QEMU/SPICE agents. |

`scripts/build/stage-live-config.sh` copies these lists into the live-build
tree; `scripts/validation/check-packages.sh` resolves all 85 entries against
Debian trixie.

## Category directories

The empty directories record the intended split of the cloud-administration
toolset:

- `core/` — base system and shell utilities.
- `security/` — firewall, hardening and audit tools.
- `monitoring/` — metrics, logs and process inspection.
- `networking/` — network diagnosis and remote access.
- `storage/` — filesystems, backup and disk tools.
- `administration/` — configuration management and automation.
- `utilities/` — small convenience tools.

Whether these become the source of truth (`packages/<category>/*.list` staged
into `debian/package-lists/`) or stay documentation is still open; the
current lists were written directly in `debian/package-lists/`.  Cloud tools
that Debian does not package (Terraform, kubectl binaries, gcloud, azure-cli
extras) have no decision yet.
