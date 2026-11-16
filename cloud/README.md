# Cloud Administration

"Cloud Administration" is the project focus.  The image ships the Debian
trixie packages that cover the core workflow: `ansible`, `awscli`,
`azure-cli`, `kubectl` (`kubernetes-client`), `python3` with pip/venv,
`git`, `openssh-client`, `yq`, plus the local tooling in `packages/`
(monitoring, capture, storage, backups and shell utilities).

There are no cloud images, Terraform modules, cluster manifests, API keys or
service integrations in this repository.

## Tools outside Debian main

The maintainer chose **not to install** them for 0.1.0-dev: no third-party
repositories, no vendor keys, no first-boot download.  This keeps the ISO
reproducible from trixie alone and makes it testable offline.

Not installed: Terraform, Packer, Helm, k9s, kubens, minikube, helmfile,
Google Cloud SDK (`gcloud`/`gsutil`), sops, trivy, Vault, Nomad, Consul,
Boundary, `doctl`, `hcloud`, lazydocker, ansible-navigator, cri-tools and
docker-ce.

If you need one, install it yourself from the vendor's signed release and
verify its checksum/signature.  Typical shapes (follow the current vendor
documentation, not this list, for URLs and versions):

```sh
# Example: a single static binary into ~/.local/bin
install -d "$HOME/.local/bin"
# download the release archive, verify its checksum, then:
install -m 0755 ./terraform "$HOME/.local/bin/terraform"
```

Vendor repositories (HashiCorp, Google, Docker) each add an apt source and
signing key; they are not configured in this image.

## Intended domains

The empty directories describe where cloud material will live once there is
some:

- `administration/` — accounts, quotas, cost and access policy.
- `automation/` — provisioning and configuration workflows.
- `documentation/` — how-to material for cloud tasks.
- `configuration/` — shared configuration for the tools above.
- `infrastructure/` — reference infrastructure definitions.
- `monitoring/` — metrics, alerting and log collection.
- `networking/` — VPC/VNet, DNS, load balancing and VPN.
- `storage/` — object storage, volumes and backup.
