#!/usr/bin/env bash
## Verify the SHA-256 checksum of the built ISO.
##
## Usage: scripts/validation/checksum.sh [ISO]
## Default ISO: build/output/velcora-<VERSION>-amd64.iso

set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$REPO_ROOT/VERSION")"
ISO="${1:-$REPO_ROOT/build/output/velcora-$VERSION-amd64.iso}"
SUM="$ISO.sha256"

die() { printf 'checksum: %s\n' "$*" >&2; exit 1; }

[[ -f "$ISO" ]] || die "ISO not found: $ISO (run 'make iso' first)"
[[ -f "$SUM" ]] || die "checksum file not found: $SUM (the build writes it next to the ISO)"

expected="$(awk 'NR == 1 { print $1 }' "$SUM")"
actual="$(sha256sum "$ISO" | awk '{ print $1 }')"

[[ "$expected" =~ ^[0-9a-f]{64}$ ]] || die "malformed SHA-256 in $SUM"
[[ "$actual" == "$expected" ]] \
	|| die "checksum mismatch for ${ISO##*/}: expected $expected, got $actual"

printf 'OK — %s matches %s\n' "${ISO##*/}" "${SUM##*/}"
