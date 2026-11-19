#!/usr/bin/env bash
## Build the VELCORA live ISO inside a disposable Debian container.
##
## Usage: scripts/build/build-iso.sh
## Env:   VELCORA_BUILDER_IMAGE  Debian image to build in (default debian:trixie)
##        DOCKER                 Container runtime (default docker)

set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LIVE_DIR="$REPO_ROOT/build/live-build"
WORK_DIR="$REPO_ROOT/build/work/live"
OUT_DIR="$REPO_ROOT/build/output"
VERSION="$(tr -d '[:space:]' < "$REPO_ROOT/VERSION")"
ISO_NAME="velcora-${VERSION}-live-amd64.iso"
BUILDER_IMAGE="${VELCORA_BUILDER_IMAGE:-debian:trixie}"
DOCKER="${DOCKER:-docker}"
MIN_FREE_GIB="${VELCORA_MIN_FREE_GIB:-15}"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
die() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

trap 'die "ISO build failed; inspect the output above and ${WORK_DIR}/live-build"' ERR

[[ -f "$REPO_ROOT/VERSION" ]] || die "VERSION file is missing"
VERSION="${VERSION//[[:space:]]/}"
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9.]+)?$ ]] \
	|| die "VERSION '$VERSION' is not a valid version string"
[[ -x "$LIVE_DIR/auto/config" ]] || die "build/live-build/auto/config is missing or not executable"
command -v "$DOCKER" >/dev/null 2>&1 || die "$DOCKER is required to build the ISO"
"$DOCKER" info >/dev/null 2>&1 || die "cannot connect to the Docker daemon"

free_kib="$(df -Pk "$REPO_ROOT" | awk 'NR==2 {print $4}')"
(( free_kib >= MIN_FREE_GIB * 1024 * 1024 )) \
	|| die "at least ${MIN_FREE_GIB} GiB free disk is required (found $((free_kib / 1024 / 1024)) GiB)"

log "VELCORA ${VERSION} — building amd64 live ISO with ${BUILDER_IMAGE}"

rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR" "$OUT_DIR"
cp -a "$LIVE_DIR" "$WORK_DIR/live-build"
cp "$REPO_ROOT/VERSION" "$WORK_DIR/VERSION"

log "Rendering branding and staging sources, then running lb config and lb build"
log "(this takes 20–40 minutes on a first build)"
"$DOCKER" run --rm --privileged \
	--env VELCORA_VERSION="$VERSION" \
	--env HOST_UID="$(id -u)" \
	--env HOST_GID="$(id -g)" \
	--volume "$WORK_DIR:/work" \
	--volume "$REPO_ROOT:/source:ro" \
	--workdir /work/live-build \
	"$BUILDER_IMAGE" \
	bash -euo pipefail -c '
		export DEBIAN_FRONTEND=noninteractive
		printf "Acquire::Retries \"8\";\nAcquire::http::Timeout \"30\";\n" \
			> /etc/apt/apt.conf.d/90retries
		apt-get update
		apt-get install -y --no-install-recommends \
			live-build ca-certificates python3 librsvg2-bin \
			dosfstools mtools squashfs-tools xorriso \
			isolinux syslinux-common syslinux-efi \
			grub-pc-bin grub-efi-amd64-bin >/dev/null
		trap '"'"'chown -R "${HOST_UID}:${HOST_GID}" /work'"'"' EXIT
		python3 /source/scripts/build/render-boot-branding.py \
			--repo /source --output /work/generated
		python3 /source/scripts/build/sync-branding-assets.py \
			--repo /source --output /work/generated/includes.chroot
		bash /source/scripts/build/stage-live-config.sh \
			--source /source --target /work/live-build \
			--generated /work/generated
		lb config
		lb build
	' 2>&1 | tee "$OUT_DIR/build.log"

shopt -s nullglob
isos=("$WORK_DIR"/live-build/*.hybrid.iso)
(( ${#isos[@]} == 1 )) || die "expected one hybrid ISO, found ${#isos[@]}"
mv "${isos[0]}" "$OUT_DIR/$ISO_NAME"
( cd "$OUT_DIR" && sha256sum "$ISO_NAME" > "$ISO_NAME.sha256" )

log "ISO ready: $OUT_DIR/$ISO_NAME"
ls -lh "$OUT_DIR/$ISO_NAME" "$OUT_DIR/$ISO_NAME.sha256"
