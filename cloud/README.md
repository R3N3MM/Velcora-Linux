# Cloud Administration

Status: **placeholder.**  Every directory here is empty and no build step
reads this folder.  "Cloud Administration" is the project focus, but the
image currently ships only the Debian-packaged clients listed in
`debian/package-lists/velcora-cloud.list.chroot`: `ansible`, `awscli`,
`azure-cli`, `kubernetes-client`, `python3` with pip/venv/requests/yaml,
`git`, `openssh-client` and `yq`.

There are no cloud images, Terraform modules, cluster manifests, API keys or
service integrations in this repository.

## Intended domains

- `administration/` — accounts, quotas, cost and access policy.
- `automation/` — provisioning and configuration workflows.
- `configuration/` — shared configuration for the tools above.
- `documentation/` — how-to material for cloud tasks.
- `infrastructure/` — reference infrastructure definitions.
- `monitoring/` — metrics, alerting and log collection.
- `networking/` — VPC/VNet, DNS, load balancing and VPN.
- `storage/` — object storage, volumes and backup.

## Tools Debian does not package

Terraform, the kubectl binary, gcloud, AWS session tooling beyond `awscli`,
and Helm are not in Debian trixie main.  They are not installed and no
decision has been taken between skipping them, adding a third-party
repository, or offering a first-boot installer.
