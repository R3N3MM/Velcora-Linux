# Repository and governance

Status: **placeholder.**  The directories here are empty.  This folder is not
an APT repository: there is no `dists/`, `pool/`, signing key or package
archive, and the image installs only from Debian's own mirrors plus the
pinned unstable/contrib source used for the VirtualBox guest tools.

## Where releases live

ISOs are built in CI and published as GitHub release assets, split because
GitHub caps an asset at 2 GiB.  `scripts/release/publish-iso.sh` performs the
split and upload.

## Intended domains

- `architecture/` — release and repository design decisions.
- `decisions/` — recorded architecture decision records.
- `policies/` — licensing, branding and contribution policy.
- `governance/` — project roles and decision making.

Project-wide documents currently sit at the repository root:
`CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `GOVERNANCE.md`, `SECURITY.md`,
`SUPPORT.md` and `LICENSE`.  The project's own code, configuration and
documentation are MIT licensed.
