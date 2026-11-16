# Infrastructure

Status: **placeholder.**  The directories here are empty and nothing in the
build reads them.

What exists elsewhere today:

- Build and ISO generation: `scripts/build/`, `build/live-build/`.
- CI: `.github/workflows/` (lint, package check, tagged ISO build).
- Hardening in the image: `ufw` is installed but not enabled by default;
  the live session uses passwordless sudo, which the installer removes from
  the target system.
- No signing keys, mirror, package repository or deployment automation
  exists in this repository.

## Intended domains

- `services/` — long-running services and their units.
- `system/` — base system defaults and integration points.
- `hardening/` — security baselines and audit configuration.
- `permissions/` — users, groups, sudo and access policy.
- `networking/` — host networking and firewall defaults.
- `storage/` — partition layout, mounts and backup policy.
