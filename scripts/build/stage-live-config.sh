#!/usr/bin/env bash
## Assemble the live-build configuration from the repository source areas.
##
## The top-level folders are the source of truth:
##   boot/       bootloader, Plymouth and initramfs configuration
##   desktop/    Xfce, LightDM, GTK, fonts and desktop integration
##   debian/     os-release, Calamares, apt sources, package lists and hooks
##   branding/   the artwork rendered into the image
##
## This script copies those sources into a live-build tree.  Generated
## artwork (Plymouth frames, splash.svg, wallpapers, icon theme) is produced
## first by render-boot-branding.py and sync-branding-assets.py.
##
## Usage:
##   scripts/build/stage-live-config.sh \
##       --source . --target build/work/live-build --generated build/generated

set -Eeuo pipefail

SOURCE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TARGET=""
GENERATED=""
ALLOW_MISSING_GENERATED=0

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
die() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

while (($# > 0)); do
	case "$1" in
	--source) SOURCE_ROOT="${2:?--source needs a path}"; shift 2 ;;
	--target) TARGET="${2:?--target needs a path}"; shift 2 ;;
	--generated) GENERATED="${2:?--generated needs a path}"; shift 2 ;;
	--allow-missing-generated) ALLOW_MISSING_GENERATED=1; shift ;;
	-h | --help)
		sed -n '2,22p' "${BASH_SOURCE[0]}" | sed 's/^## \{0,1\}//'
		exit 0
		;;
	*) die "unknown argument: $1" ;;
	esac
done

[[ -n "$TARGET" ]] || die "--target is required"
SOURCE_ROOT="$(cd "$SOURCE_ROOT" && pwd)"
[[ -z "$GENERATED" ]] || GENERATED="$(realpath -m "$GENERATED")"

CONFIG="$TARGET/config"
INCLUDES="$CONFIG/includes.chroot"

copy_tree() {
	local source="$1" destination="$2"
	[[ -d "$source" ]] || die "missing source directory: ${source#"$SOURCE_ROOT"/}"
	mkdir -p "$destination"
	cp -a "$source/." "$destination/"
}

for directory in boot boot/bootloaders boot/hooks boot/plymouth/velcora \
	debian debian/apt debian/archives debian/base debian/hooks \
	debian/installer debian/package-lists debian/vm \
	desktop desktop/autostart desktop/fonts desktop/gtk-3.0 \
	desktop/lightdm desktop/xfce; do
	[[ -d "$SOURCE_ROOT/$directory" ]] \
		|| die "missing source directory: $directory"
done

log "staging source configuration into $TARGET"
rm -rf "$CONFIG"
mkdir -p "$CONFIG/apt" "$CONFIG/archives" "$CONFIG/package-lists" \
	"$CONFIG/bootloaders" "$CONFIG/hooks/normal" "$INCLUDES"

# live-build configuration directories.
cp -a "$SOURCE_ROOT/debian/apt/." "$CONFIG/apt/"
cp -a "$SOURCE_ROOT/debian/archives/." "$CONFIG/archives/"
cp -a "$SOURCE_ROOT/debian/package-lists/." "$CONFIG/package-lists/"
cp -a "$SOURCE_ROOT/boot/bootloaders/." "$CONFIG/bootloaders/"
cp -a "$SOURCE_ROOT/debian/hooks/." "$CONFIG/hooks/normal/"
cp -a "$SOURCE_ROOT/boot/hooks/." "$CONFIG/hooks/normal/"

# Image contents.  Each tree already mirrors its destination under /.
for tree in debian/base debian/installer debian/vm \
	desktop/xfce desktop/lightdm desktop/gtk-3.0 desktop/autostart \
	desktop/fonts; do
	copy_tree "$SOURCE_ROOT/$tree" "$INCLUDES"
done

# Branding typeface.  The font binary lives in branding/, not in desktop/.
install -Dm644 "$SOURCE_ROOT/branding/fonts/inter/InterVariable.ttf" \
	"$INCLUDES/usr/share/fonts/truetype/velcora/InterVariable.ttf"
install -Dm644 "$SOURCE_ROOT/branding/fonts/inter/InterVariable-Italic.ttf" \
	"$INCLUDES/usr/share/fonts/truetype/velcora/InterVariable-Italic.ttf"
install -Dm644 "$SOURCE_ROOT/branding/fonts/inter/LICENSE.txt" \
	"$INCLUDES/usr/share/doc/fonts-inter-velcora/LICENSE.txt"

# Terminal typeface.  JetBrains Mono is selected only by xfce4-terminal
# (desktop/xfce/.../xfce4-terminal.xml); the desktop and every other GTK
# application keep Inter.  The NL (no-ligature) family is deliberately not
# installed, so the ligature faces are the ones fontconfig resolves.
for face in "$SOURCE_ROOT"/branding/fonts/jetbrains-mono/ttf/JetBrainsMono-*.ttf; do
	install -Dm644 "$face" \
		"$INCLUDES/usr/share/fonts/truetype/velcora/${face##*/}"
done
for doc in OFL.txt AUTHORS.txt README.md; do
	install -Dm644 "$SOURCE_ROOT/branding/fonts/jetbrains-mono/$doc" \
		"$INCLUDES/usr/share/doc/fonts-jetbrains-mono-velcora/$doc"
done

# Generated artwork.  A normal build always renders this first; static
# validation can skip it with --allow-missing-generated.
if [[ -n "$GENERATED" && -d "$GENERATED" ]]; then
	if [[ -d "$GENERATED/includes.chroot" ]]; then
		copy_tree "$GENERATED/includes.chroot" "$INCLUDES"
	fi
	if [[ -f "$GENERATED/bootloaders/splash.svg" ]]; then
		install -Dm644 "$GENERATED/bootloaders/splash.svg" \
			"$CONFIG/bootloaders/splash.svg"
	fi
else
	(( ALLOW_MISSING_GENERATED == 1 )) \
		|| die "generated assets are missing: ${GENERATED:-<not set>}"
	log "generated assets not present; continuing with sources only"
fi

# Plymouth theme description and script are source files, not rendered.
THEME="$INCLUDES/usr/share/plymouth/themes/velcora"
install -Dm644 "$SOURCE_ROOT/boot/plymouth/velcora/velcora.plymouth" \
	"$THEME/velcora.plymouth"
install -Dm644 "$SOURCE_ROOT/boot/plymouth/velcora/velcora.script" \
	"$THEME/velcora.script"

[[ -x "$CONFIG/hooks/normal/0200-velcora-installer.hook.chroot" ]] \
	|| chmod +x "$CONFIG/hooks/normal/0200-velcora-installer.hook.chroot"
[[ -x "$CONFIG/hooks/normal/0100-velcora-branding.hook.chroot" ]] \
	|| chmod +x "$CONFIG/hooks/normal/0100-velcora-branding.hook.chroot"

log "staged configuration:"
find "$CONFIG" -maxdepth 2 -mindepth 1 -type d | sort | sed 's/^/    /'
