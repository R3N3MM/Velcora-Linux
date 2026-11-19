#!/usr/bin/env bash
## Build the Velcora Debian Installer ISO in an isolated Debian container.
## Env: DOCKER, VELCORA_BUILDER_IMAGE, VELCORA_MIN_FREE_GIB

set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$REPO_ROOT/VERSION")"
WORK_DIR="$REPO_ROOT/build/work/installer-cdd"
OUT_DIR="$REPO_ROOT/build/output"
ISO_NAME="velcora-${VERSION}-installer-amd64.iso"
BUILDER_IMAGE="${VELCORA_BUILDER_IMAGE:-debian:trixie}"
DOCKER="${DOCKER:-docker}"
MIN_FREE_GIB="${VELCORA_MIN_FREE_GIB:-25}"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
die() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }
trap 'die "Installer ISO build failed; inspect ${OUT_DIR}/installer-build.log and ${WORK_DIR}"' ERR

command -v "$DOCKER" >/dev/null 2>&1 || die "$DOCKER is required"
"$DOCKER" info >/dev/null 2>&1 || die "cannot connect to the Docker daemon"
free_kib="$(df -Pk "$REPO_ROOT" | awk 'NR==2 {print $4}')"
(( free_kib >= MIN_FREE_GIB * 1024 * 1024 )) \
	|| die "at least ${MIN_FREE_GIB} GiB free disk is required (found $((free_kib / 1024 / 1024)) GiB)"

rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR/profiles" "$WORK_DIR/packages" "$OUT_DIR"
cp "$REPO_ROOT/installer/profiles/default.preseed" "$WORK_DIR/profiles/"
cp "$REPO_ROOT/installer/profiles/velcora.preseed" "$WORK_DIR/profiles/"
cp "$REPO_ROOT/installer/profiles/velcora.conf" "$WORK_DIR/profiles/"
"$REPO_ROOT/scripts/build/generate-installer-profile.sh" \
	--source "$REPO_ROOT" --output "$WORK_DIR/profiles/velcora.packages"
cat > "$WORK_DIR/simple-cdd.conf" <<'EOF'
export ARCH=amd64
export ARCHES=amd64
CODENAME=trixie
debian_mirror="http://deb.debian.org/debian/"
security_mirror="http://security.debian.org/debian-security/"
profiles="velcora"
auto_profiles="velcora"
export CDNAME=velcora
EOF

log "Building the Velcora Debian Installer image"
log "The DVD contains the selected package set for offline installation"
"$DOCKER" run --rm --privileged \
	--env VERSION="$VERSION" \
	--env HOST_UID="$(id -u)" \
	--env HOST_GID="$(id -g)" \
	--volume "$WORK_DIR:/work" \
	--volume "$REPO_ROOT:/source:ro" \
	--workdir /work \
	"$BUILDER_IMAGE" \
	bash -euo pipefail -c '
		export DEBIAN_FRONTEND=noninteractive
		printf 'Acquire::Retries "8";\nAcquire::http::Timeout "30";\n' \
			> /etc/apt/apt.conf.d/90retries
		apt-get update
		apt-get install -y --no-install-recommends \
			simple-cdd dpkg-dev python3 librsvg2-bin ca-certificates \
			fonts-dejavu-core >/dev/null
		trap '\''chown -R "${HOST_UID}:${HOST_GID}" /work'\'' EXIT

		python3 /source/scripts/build/render-boot-branding.py \
			--repo /source --output /work/generated
		python3 /source/scripts/build/sync-branding-assets.py \
			--repo /source --output /work/generated/includes.chroot
		rsvg-convert -w 640 -h 480 --background-color="#07101e" \
			-o /work/installer-splash.png /source/branding/logo/velcora-logo.svg
		export SPLASHPNG=/work/installer-splash.png

		pkg=/work/branding-package
		mkdir -p "$pkg/DEBIAN" "$pkg/etc" "$pkg/usr/share/velcora" \
			"$pkg/usr/local/bin" "$pkg/usr/share/applications" \
			"$pkg/usr/share/backgrounds" "$pkg/usr/share/icons" \
			"$pkg/usr/share/plymouth/themes/velcora" \
			"$pkg/usr/share/fonts/truetype/velcora" \
			"$pkg/usr/share/doc/fonts-inter-velcora" \
			"$pkg/usr/share/doc/fonts-jetbrains-mono-velcora"
		sed "s/^Version:.*/Version: ${VERSION}/" \
			/source/installer/branding-package/control > "$pkg/DEBIAN/control"
		install -m755 /source/installer/branding-package/postinst "$pkg/DEBIAN/postinst"
		install -m755 /source/debian/installer/usr/local/bin/velcora-tweaks \
			"$pkg/usr/local/bin/velcora-tweaks"
		install -m644 /source/debian/installer/usr/share/applications/velcora-tweaks.desktop \
			"$pkg/usr/share/applications/velcora-tweaks.desktop"
		printf "%s\\n" "$VERSION" > "$pkg/usr/share/velcora/version"
		install -m644 /source/debian/base/etc/issue "$pkg/etc/issue"
		install -m644 /source/debian/base/etc/issue.net "$pkg/etc/issue.net"
		install -D -m644 /source/debian/base/etc/default/prometheus-node-exporter \
			"$pkg/etc/default/prometheus-node-exporter"
		cp -a /source/desktop/gtk-3.0/etc/. "$pkg/etc/"
		cp -a /source/desktop/lightdm/etc/. "$pkg/etc/"
		cp -a /source/desktop/fonts/etc/. "$pkg/etc/"
		cp -a /source/desktop/xfce/etc/. "$pkg/etc/"
		cp -a /source/branding/fonts/inter/InterVariable*.ttf "$pkg/usr/share/fonts/truetype/velcora/"
		install -m644 /source/branding/fonts/inter/LICENSE.txt \
			"$pkg/usr/share/doc/fonts-inter-velcora/LICENSE.txt"
		cp -a /source/branding/fonts/jetbrains-mono/ttf/JetBrainsMono-*.ttf \
			"$pkg/usr/share/fonts/truetype/velcora/"
		for doc in OFL.txt AUTHORS.txt README.md; do
			install -m644 "/source/branding/fonts/jetbrains-mono/$doc" \
				"$pkg/usr/share/doc/fonts-jetbrains-mono-velcora/$doc"
		done
		cp -a /work/generated/includes.chroot/usr/share/backgrounds/velcora \
			"$pkg/usr/share/backgrounds/"
		cp -a /work/generated/includes.chroot/usr/share/icons/Velcora \
			"$pkg/usr/share/icons/"
		cp -a /work/generated/includes.chroot/usr/share/velcora \
			"$pkg/usr/share/"
		cp -a /work/generated/includes.chroot/usr/share/plymouth/themes/velcora/. \
			"$pkg/usr/share/plymouth/themes/velcora/"
		install -m644 /source/boot/plymouth/velcora/velcora.plymouth \
			"$pkg/usr/share/plymouth/themes/velcora/velcora.plymouth"
		install -m644 /source/boot/plymouth/velcora/velcora.script \
			"$pkg/usr/share/plymouth/themes/velcora/velcora.script"
		dpkg-deb --build --root-owner-group "$pkg" \
			"/work/packages/velcora-branding_${VERSION}_all.deb"

		cd /work
		build-simple-cdd --conf /work/simple-cdd.conf \
			--dist trixie --profiles velcora --auto-profiles velcora \
			--local-packages /work/packages --dvd --force-root
	' 2>&1 | tee "$OUT_DIR/installer-build.log"

shopt -s nullglob
isos=("$WORK_DIR"/images/*.iso)
(( ${#isos[@]} == 1 )) || die "expected one installer DVD ISO, found ${#isos[@]}"
mv "${isos[0]}" "$OUT_DIR/$ISO_NAME"
( cd "$OUT_DIR" && sha256sum "$ISO_NAME" > "$ISO_NAME.sha256" )

log "Installer ISO ready: $OUT_DIR/$ISO_NAME"
ls -lh "$OUT_DIR/$ISO_NAME" "$OUT_DIR/$ISO_NAME.sha256"
