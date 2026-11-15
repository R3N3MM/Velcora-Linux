#!/usr/bin/env bash
## Publish the built ISO as GitHub release assets.
##
## GitHub caps each release asset at 2 GiB, and a VELCORA ISO is slightly
## larger than that, so the image is split into parts that are uploaded
## together with checksums and join instructions.
##
## Usage: scripts/release/publish-iso.sh [--dry-run]
## Env:   REPO   GitHub repository (default R3N3MM/Velcora-Linux)
##        TAG    Release tag (default v<version>)
##        PART_SIZE  split(1) chunk size (default 1100M)

set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$REPO_ROOT/VERSION")"
REPO="${REPO:-R3N3MM/Velcora-Linux}"
TAG="${TAG:-v$VERSION}"
PART_SIZE="${PART_SIZE:-1100M}"
ISO_NAME="velcora-${VERSION}-amd64.iso"
ISO="$REPO_ROOT/build/output/$ISO_NAME"
REL_DIR="$REPO_ROOT/build/output/release/$TAG"
ASSET_LIMIT=$((2 * 1024 * 1024 * 1024))
DRY_RUN=0

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
die() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

for arg in "$@"; do
	case "$arg" in
		--dry-run) DRY_RUN=1 ;;
		-h|--help) sed -n '2,12p' "$0" | sed 's/^## \{0,1\}//'; exit 0 ;;
		*) die "unknown argument: $arg" ;;
	esac
done

command -v gh >/dev/null 2>&1 || die "gh (GitHub CLI) is required"
[[ -f "$ISO" ]] || die "ISO not found: $ISO (run 'make iso' first)"
gh auth status >/dev/null 2>&1 || die "gh is not authenticated; run 'gh auth login'"

iso_size="$(stat -c %s "$ISO")"
free_kib="$(df -Pk "$REPO_ROOT" | awk 'NR==2 {print $4}')"
(( free_kib >= 3 * 1024 * 1024 )) \
	|| die "at least 3 GiB free disk is required to stage the release parts"

log "Staging $TAG from $ISO_NAME ($iso_size bytes)"
rm -rf "$REL_DIR"
mkdir -p "$REL_DIR"

split -b "$PART_SIZE" "$ISO" "$REL_DIR/$ISO_NAME.part"

shopt -s nullglob
parts=("$REL_DIR/$ISO_NAME".part*)
(( ${#parts[@]} > 0 )) || die "split produced no parts"
for part in "${parts[@]}"; do
	size="$(stat -c %s "$part")"
	(( size < ASSET_LIMIT )) || die "${part##*/} is $size bytes, over the 2 GiB asset limit"
done

# Checksums for the joined image and for every part.
(
	cd "$(dirname "$ISO")"
	sha256sum "$ISO_NAME"
	cd "$REL_DIR"
	sha256sum "$ISO_NAME".part*
) > "$REL_DIR/SHA256SUMS"

iso_sha="$(cd "$(dirname "$ISO")" && sha256sum "$ISO_NAME" | awk '{print $1}')"
iso_sha_file="$REPO_ROOT/build/output/$ISO_NAME.sha256"
if [[ -f "$iso_sha_file" ]]; then
	cp "$iso_sha_file" "$REL_DIR/$ISO_NAME.sha256"
fi

commit="$(git -C "$REPO_ROOT" rev-parse --short HEAD)"
parts_table=""
for part in "${parts[@]}"; do
	parts_table+="| \`${part##*/}\` | $(stat -c %s "$part") bytes |"$'\n'
done

notes="$REL_DIR/RELEASE_NOTES.md"
cat > "$notes" <<EOF
# VELCORA Linux $VERSION

Live ISO for BIOS and UEFI systems, built from commit \`$commit\`.

GitHub limits each release asset to 2 GiB and this image is slightly larger,
so the ISO is published in parts. Join them before booting.

$parts_table
Joined image: $iso_size bytes
SHA-256: \`$iso_sha\`

## Join the parts

Linux and macOS:

\`\`\`sh
cat $ISO_NAME.part* > $ISO_NAME
sha256sum -c $ISO_NAME.sha256
\`\`\`

Windows (Command Prompt):

\`\`\`bat
copy /b $ISO_NAME.partaa+$ISO_NAME.partab $ISO_NAME
certutil -hashfile $ISO_NAME SHA256
\`\`\`

## Run it

Boot the ISO in a virtual machine or write it to a USB drive. For Oracle
VirtualBox: Debian 64-bit, 4 GB RAM, 2 CPUs, VMSVGA, EFI enabled. See
[build/README.md](https://github.com/$REPO/blob/main/build/README.md#running-in-oracle-virtualbox).

Guest Additions are installed from VirtualBox's own disc:

\`\`\`sh
sudo velcora-install-guest-additions
\`\`\`

The live session runs from RAM, so changes are lost at reboot until the
installer phase exists.
EOF

log "Staged files:"
ls -lh "$REL_DIR"

if (( DRY_RUN )); then
	log "Dry run; would publish $TAG to $REPO with:"
	printf '  gh release create %q --repo %q --title %q --notes-file %q --prerelease --target main\n' \
		"$TAG" "$REPO" "VELCORA Linux $VERSION" "$notes"
	printf '    %s\n' "${parts[@]}" "$REL_DIR/SHA256SUMS"
	if [[ -f "$REL_DIR/$ISO_NAME.sha256" ]]; then
		printf '    %s\n' "$REL_DIR/$ISO_NAME.sha256"
	fi
	exit 0
fi

assets=("${parts[@]}" "$REL_DIR/SHA256SUMS")
if [[ -f "$REL_DIR/$ISO_NAME.sha256" ]]; then
	assets+=("$REL_DIR/$ISO_NAME.sha256")
fi

if gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1; then
	log "Release $TAG exists; uploading assets"
	gh release upload "$TAG" --repo "$REPO" --clobber "${assets[@]}"
else
	log "Creating release $TAG"
	gh release create "$TAG" --repo "$REPO" \
		--title "VELCORA Linux $VERSION" \
		--notes-file "$notes" \
		--prerelease --target main \
		"${assets[@]}"
fi

log "Published: https://github.com/$REPO/releases/tag/$TAG"
