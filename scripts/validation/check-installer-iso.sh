#!/usr/bin/env bash
## Check the Debian Installer ISO contents and BIOS/UEFI boot records.
## Usage: scripts/validation/check-installer-iso.sh [ISO]

set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$REPO_ROOT/VERSION")"
ISO="${1:-$REPO_ROOT/build/output/velcora-$VERSION-installer-amd64.iso}"
IMAGE="${VELCORA_BUILDER_IMAGE:-debian:trixie}"
DOCKER="${DOCKER:-docker}"

fail() { printf 'FAIL  %s\n' "$*" >&2; exit 1; }
log() { printf 'info  %s\n' "$*"; }

[[ -f "$ISO" ]] || fail "ISO not found: $ISO (run 'make iso-installer' first)"
iso_dir="$(cd "$(dirname "$ISO")" && pwd)"
iso_name="$(basename "$ISO")"

if command -v xorriso >/dev/null 2>&1; then
	report="$(
		xorriso -indev "$ISO" -pvd_info 2>/dev/null
		printf '%s\n' '--- EL TORITO ---'
		xorriso -indev "$ISO" -report_el_torito as_mkisofs 2>/dev/null
		printf '%s\n' '--- FILES ---'
		xorriso -indev "$ISO" -find / -type f 2>/dev/null
	)"
else
	command -v "$DOCKER" >/dev/null 2>&1 || fail "xorriso or $DOCKER is required"
	log "xorriso is absent; checking inside $IMAGE"
	report="$("$DOCKER" run --rm -v "$iso_dir:/iso:ro" "$IMAGE" bash -c '
		set -Eeuo pipefail
		apt-get update -qq
		apt-get install -y -qq --no-install-recommends xorriso >/dev/null
		xorriso -indev "/iso/$1" -pvd_info 2>/dev/null
		printf "%s\\n" "--- EL TORITO ---"
		xorriso -indev "/iso/$1" -report_el_torito as_mkisofs 2>/dev/null
		printf "%s\\n" "--- FILES ---"
		xorriso -indev "/iso/$1" -find / -type f 2>/dev/null
	' _ "$iso_name")"
fi

pvd="${report%%$'\n''--- EL TORITO ---'*}"
eltorito="${report#*'--- EL TORITO ---'$'\n'}"
files="${eltorito#*$'\n''--- FILES ---'$'\n'}"
eltorito="${eltorito%%$'\n''--- FILES ---'*}"
eltorito_flat="$(tr '\n' ' ' <<<"$eltorito")"

grep -qi 'Volume id.*VELCORA' <<<"$pvd" || fail "Installer ISO volume ID is not VELCORA"
grep -qi 'Velcora' <<<"$pvd" || fail "Installer ISO metadata does not mention Velcora"
grep -Eq -- '-b [^ ]*isolinux[^ ]*\.bin.*-no-emul-boot|-no-emul-boot.*-b [^ ]*isolinux' <<<"$eltorito_flat" \
	|| fail "Installer ISO has no BIOS boot entry"
grep -q -- '-eltorito-alt-boot' <<<"$eltorito_flat" \
	|| fail "Installer ISO has no UEFI boot entry"
grep -Eq -- '-e [^ ]*efi[^ ]*(\.img)?|-eltorito-boot [^ ]*efi' <<<"$eltorito_flat" \
	|| fail "Installer ISO has no UEFI boot image"
grep -Eq 'install\.amd/vmlinuz|install\.amd.*/vmlinuz' <<<"$files" \
	|| fail "Installer ISO does not contain the Debian Installer kernel"
grep -Eq 'install\.amd/initrd\.gz|install\.amd.*/initrd\.gz' <<<"$files" \
	|| fail "Installer ISO does not contain the Debian Installer initrd"
grep -q 'velcora-branding' <<<"$files" \
	|| fail "Installer ISO does not include the Velcora branding package"

printf 'OK — Debian Installer image, Velcora branding, BIOS and UEFI boot records\n'
