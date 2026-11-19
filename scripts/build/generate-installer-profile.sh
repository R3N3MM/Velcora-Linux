#!/usr/bin/env bash
## Generate the Simple-CDD Velcora package profile from the shared package lists.
## Usage: scripts/build/generate-installer-profile.sh --source DIR --output FILE

set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SOURCE_ROOT="$REPO_ROOT"
OUTPUT=""

while (($# > 0)); do
	case "$1" in
		--source) SOURCE_ROOT="${2:?--source needs a directory}"; shift 2 ;;
		--output) OUTPUT="${2:?--output needs a file}"; shift 2 ;;
		*) printf 'unknown argument: %s\n' "$1" >&2; exit 2 ;;
	esac
done

[[ -d "$SOURCE_ROOT/debian/package-lists" ]] || {
	printf 'missing package lists under %s\n' "$SOURCE_ROOT/debian" >&2
	exit 1
}
[[ -n "$OUTPUT" ]] || {
	printf '%s\n' '--output is required' >&2
	exit 2
}

mkdir -p "$(dirname "$OUTPUT")"
{
	for list in \
		"$SOURCE_ROOT/debian/package-lists/velcora-cloud.list.chroot" \
		"$SOURCE_ROOT/debian/package-lists/velcora-desktop.list.chroot" \
		"$SOURCE_ROOT/debian/package-lists/velcora-system.list.chroot" \
		"$SOURCE_ROOT/debian/package-lists/velcora-vm.list.chroot" \
		"$SOURCE_ROOT"/packages/*/*.list.chroot; do
		[[ -f "$list" ]] || continue
		sed -e 's/#.*//' "$list"
	done
	# These VirtualBox userspace packages are sourced from Debian unstable in
	# the live-build image and are intentionally not in the trixie installer.
	printf '%s\n' velcora-branding
} | awk 'NF { print $1 }' \
	| grep -vxE 'task-xfce-desktop|virtualbox-guest-(utils|x11)' \
	| sort -u > "$OUTPUT"

if ! grep -qx velcora-branding "$OUTPUT"; then
	printf 'velcora-branding was not added to the installer package profile\n' >&2
	exit 1
fi
if grep -qxE 'calamares|calamares-settings-debian|task-xfce-desktop|virtualbox-guest-(utils|x11)' "$OUTPUT"; then
	printf 'the Debian Installer profile includes a live-only package\n' >&2
	exit 1
fi

printf 'Generated %s packages for the Simple-CDD profile\n' "$(wc -l < "$OUTPUT")"
