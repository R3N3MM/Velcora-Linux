# Package sets

`packages/<category>/` holds the cloud-administration tooling that is added
on top of the base image.  Each file is a live-build package list named
`velcora-<category>.list.chroot`; `scripts/build/stage-live-config.sh` copies
them into the live-build `package-lists/` directory next to the five files in
`debian/package-lists/`.

All 55 entries are Debian 13 (trixie) **main** and are resolved by
`scripts/validation/check-packages.sh` (140 packages across 12 lists).

| File | Packages |
| --- | --- |
| `core/velcora-core.list.chroot` | file, lsof, psmisc, pciutils, usbutils, strace, time |
| `security/velcora-security.list.chroot` | apparmor, apparmor-utils, auditd, aide, lynis, rkhunter, unattended-upgrades, needrestart |
| `monitoring/velcora-monitoring.list.chroot` | prometheus-node-exporter, sysstat, btop, iotop, iftop, lm-sensors |
| `networking/velcora-networking.list.chroot` | nmap, tcpdump, tshark, mtr-tiny, traceroute, bind9-dnsutils, socat, netcat-openbsd, ethtool, iperf3, wireguard-tools, sshfs |
| `storage/velcora-storage.list.chroot` | ncdu, smartmontools, gdisk, lvm2, mdadm, nfs-common, cifs-utils, restic, hdparm, testdisk |
| `administration/velcora-administration.list.chroot` | pipx, ansible-lint, open-vm-tools, debootstrap |
| `utilities/velcora-utilities.list.chroot` | tree, bat, fd-find, ripgrep, fzf, pv, 7zip, mc |

The base desktop, system, cloud-client, VM and installer sets stay in
`debian/package-lists/`.  Validation rejects a package that appears in both
places.

## Why these, briefly

`core/` covers file, process, port and hardware inspection.  `security/`
adds AppArmor, audit and integrity baselines plus automated updates.
`monitoring/` gives local metrics and an exporter for Prometheus.
`networking/` covers capture, path diagnosis, throughput and WireGuard.
`storage/` covers SMART, LVM/RAID, network filesystems and restic backups.
`administration/` adds Ansible linting, isolated Python CLIs, VMware guest
tools and debootstrap.  `utilities/` is the day-to-day shell convenience set.
One-line reasons per package live in the list headers.

Deliberately absent: `fail2ban` (no SSH server in the image), `openvpn` and
the Qt Wireshark GUI (size), `borgbackup` (restic is the chosen backup tool),
and container runtimes — install `docker.io` or `podman` yourself if needed.

`prometheus-node-exporter` is bound to `127.0.0.1:9100` by
`debian/base/etc/default/prometheus-node-exporter`, so a fresh install does
not expose metrics on every interface.  Change that file and restart the
service to let a Prometheus server scrape over the network.

## Size

Measured in a trixie container with the build's recommends setting: the set
adds **453 MiB installed** (313 MiB without recommends), which is roughly
**140–190 MiB compressed** in the squashfs.  The image was already
2,227,011,584 bytes (2.07 GiB) before this set, so expect about **2.2 GiB**
and a three-part split release.  The ISO does not fit under 2 GiB; if that
becomes a requirement, cut from `networking/`, `utilities/` and `storage/`
first.

## Adding a package

1. Confirm it is in trixie main:
   `docker run --rm debian:trixie apt-cache policy <package>`.
2. Add it to the right category list with a one-line comment saying why.
3. Run `./scripts/validation/check-packages.sh` and `make lint`.
4. Keep the package out of the five `debian/package-lists/` files unless it
   is part of the base desktop, system, cloud-client, VM or installer set.

## Tools outside Debian main

Terraform, Packer, Helm, k9s, kubens, minikube, helmfile, gcloud, sops,
trivy, Vault/Nomad/Consul/Boundary, doctl, hcloud, lazydocker,
ansible-navigator, cri-tools and docker-ce are **not installed**.  The
maintainer chose to skip them for 0.1.0-dev so the image stays reproducible
from trixie alone, with no vendor keys and no first-boot downloads.  See
`cloud/README.md` for the manual install path.
