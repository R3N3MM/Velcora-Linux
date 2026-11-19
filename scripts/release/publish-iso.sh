#!/usr/bin/env bash
## Publish both Velcora ISOs as GitHub release assets.
## GitHub's 2 GiB asset limit is handled by splitting larger images.
## Usage: scripts/release/publish-iso.sh [--dry-run]

set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$REPO_ROOT/VERSION")"
REPO="${REPO:-R3N3MM/Velcora-Linux}"
TAG="${TAG:-v$VERSION}"
PART_SIZE="${PART_SIZE:-1500M}"
REL_DIR="$REPO_ROOT/build/output/release/$TAG"
ASSET_LIMIT=$((2 * 1024 * 1024 * 1024))
DRY_RUN=0

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
die() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

for arg in "$@"; do
	case "$arg" in
		--dry-run) DRY_RUN=1 ;;
		-h|--help) sed -n '2,5p' "$0" | sed 's/^## \{0,1\}//'; exit 0 ;;
		*) die "unknown argument: $arg" ;;
	esac
done

command -v gh >/dev/null 2>&1 || die "gh (GitHub CLI) is required"
sources=("$REPO_ROOT/build/output/velcora-$VERSION-live-amd64.iso"
	"$REPO_ROOT/build/output/velcora-$VERSION-installer-amd64.iso")
for iso in "${sources[@]}"; do [[ -f "$iso" ]] || die "ISO not found: $iso (run 'make iso' first)"; done

rm -rf "$REL_DIR"
mkdir -p "$REL_DIR"
assets=()
notes="$REL_DIR/RELEASE_NOTES.md"
checksums="$REL_DIR/SHA256SUMS"
: > "$checksums"

for iso in "${sources[@]}"; do
	name="${iso##*/}"
	size="$(stat -c %s "$iso")"
	sha="$(sha256sum "$iso" | awk '{print $1}')"
	if (( size < ASSET_LIMIT )); then
		cp "$iso" "$REL_DIR/$name"
		assets+=("$REL_DIR/$name")
	else
		split -b "$PART_SIZE" "$iso" "$REL_DIR/$name.part"
		shopt -s nullglob
		parts=("$REL_DIR/$name".part*)
		(( ${#parts[@]} > 0 )) || die "split produced no parts for $name"
		for part in "${parts[@]}"; do
			(( $(stat -c %s "$part") < ASSET_LIMIT )) || die "${part##*/} exceeds GitHub's asset limit"
		done
		assets+=("${parts[@]}")
		printf 'cat %s.part* > %s\n' "$name" "$name" >> "$REL_DIR/JOIN.sh"
	fi
	printf '%s  %s\n' "$sha" "$name" >> "$checksums"
	printf '\n### %s\n\n- Size: %s bytes\n- SHA-256: `%s`\n' "$name" "$size" "$sha" >> "$REL_DIR/IMAGE_TABLE.md"
done

if [[ -f "$REL_DIR/JOIN.sh" ]]; then
	for part in "$REL_DIR"/*.part*; do sha256sum "$part" >> "$checksums"; done
	assets+=("$REL_DIR/JOIN.sh")
fi
assets+=("$checksums")
commit="$(git -C "$REPO_ROOT" rev-parse --short HEAD)"
cat > "$notes" <<EOF
# VELCORA Linux $VERSION

Live desktop and Debian Installer images for amd64, built from commit `$commit`.

## Downloads and checksums

$(cat "$REL_DIR/IMAGE_TABLE.md")

If an image is split into parts, join them in filename order before booting.
The included `JOIN.sh` shows the commands. Verify the joined image with
`sha256sum -c SHA256SUMS`.

The Live image boots into Xfce and includes Calamares. The Installer image
boots Debian Installer directly and includes Velcora's selected package set.
Both images support BIOS and UEFI. These are development images; a full disk
installation has not yet been verified end to end.
EOF
rm -f "$REL_DIR/IMAGE_TABLE.md"
assets+=("$notes")

log "Staged release assets:"
ls -lh "$REL_DIR"
if (( DRY_RUN )); then
	log "Dry run; no release was uploaded."
	exit 0
fi
gh auth status >/dev/null 2>&1 || die "gh is not authenticated; run 'gh auth login'"
if gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1; then
	gh release upload "$TAG" --repo "$REPO" --clobber "${assets[@]}"
else
	gh release create "$TAG" --repo "$REPO" --title "VELCORA Linux $VERSION" \
		--notes-file "$notes" --prerelease --target main "${assets[@]}"
fi
log "Published: https://github.com/$REPO/releases/tag/$TAG"
