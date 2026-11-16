#!/usr/bin/env bash
## Check that the built ISO is a hybrid BIOS + UEFI image.
##
## Usage: scripts/validation/check-iso.sh [ISO]
## Default ISO: build/output/velcora-<VERSION>-amd64.iso
##
## Uses host xorriso when available and otherwise a disposable Debian
## container, so the check works on a host without live-build installed.

set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$REPO_ROOT/VERSION")"
ISO="${1:-$REPO_ROOT/build/output/velcora-$VERSION-amd64.iso}"
IMAGE="${VELCORA_BUILDER_IMAGE:-debian:trixie}"
DOCKER="${DOCKER:-docker}"

fail() { printf 'FAIL  %s\n' "$*" >&2; exit 1; }
log() { printf 'info  %s\n' "$*"; }

[[ -f "$ISO" ]] || fail "ISO not found: $ISO (run 'make iso' first)"

iso_dir="$(cd "$(dirname "$ISO")" && pwd)"
iso_name="$(basename "$ISO")"

if command -v xorriso >/dev/null 2>&1; then
	report="$(
		xorriso -indev "$ISO" -pvd_info 2>/dev/null
		printf '%s\n' '--- EL TORITO ---'
		xorriso -indev "$ISO" -report_el_torito as_mkisofs 2>/dev/null
		printf '%s\n' '--- FILESYSTEM ---'
		xorriso -indev "$ISO" -find /live/filesystem.squashfs -type f 2>/dev/null
	)"
else
	command -v "$DOCKER" >/dev/null 2>&1 \
		|| fail "xorriso is not installed and $DOCKER is unavailable"
	log "xorriso is absent; checking inside $IMAGE"
	report="$(
		"$DOCKER" run --rm -v "$iso_dir:/iso:ro" "$IMAGE" bash -c '
			set -Eeuo pipefail
			export DEBIAN_FRONTEND=noninteractive
			apt-get update -qq
			apt-get install -y -qq --no-install-recommends xorriso >/dev/null
			xorriso -indev "/iso/$1" -pvd_info 2>/dev/null
			printf "%s\n" "--- EL TORITO ---"
			xorriso -indev "/iso/$1" -report_el_torito as_mkisofs 2>/dev/null
			printf "%s\n" "--- FILESYSTEM ---"
			xorriso -indev "/iso/$1" -find /live/filesystem.squashfs -type f 2>/dev/null
		' _ "$iso_name"
	)"
fi

pvd="${report%%$'\n''--- EL TORITO ---'*}"
eltorito="${report#*'--- EL TORITO ---'$'\n'}"
eltorito="${eltorito%%$'\n''--- FILESYSTEM ---'*}"

grep -qi 'Volume id.*VELCORA' <<<"$pvd" \
	|| fail "ISO volume ID is not VELCORA"
grep -qi 'Velcora Linux' <<<"$pvd" \
	|| fail "ISO application ID does not mention Velcora Linux"

grep -Eq -- "-b [^ ]*isolinux[^ ]*\.bin.*-no-emul-boot|-no-emul-boot.*-b [^ ]*isolinux" <<<"$eltorito" \
	|| fail "no BIOS El Torito entry (isolinux.bin)"
grep -q -- '-eltorito-alt-boot' <<<"$eltorito" \
	|| fail "no UEFI El Torito entry (missing -eltorito-alt-boot)"
grep -Eq -- "-e [^ ]*efi[^ ]*(\.img)?|-eltorito-boot [^ ]*efi" <<<"$eltorito" \
	|| fail "no UEFI boot image in the El Torito record"
grep -q '/live/filesystem.squashfs' <<<"$report" \
	|| fail "the ISO does not contain /live/filesystem.squashfs"

printf 'OK — hybrid BIOS and UEFI image, volume VELCORA\n'
