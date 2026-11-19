#!/usr/bin/env bash
## Static checks for the VELCORA source tree and live-build configuration.
## Run before an ISO build; used by CI and `make validate`.
##
## Generated artwork is validated when build/generated exists.  A normal
## `make iso` renders it first and then runs the same staging path.

set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LIVE_DIR="$REPO_ROOT/build/live-build"
GENERATED="$REPO_ROOT/build/generated"
BOOT="$REPO_ROOT/boot"
DEBIAN="$REPO_ROOT/debian"
DESKTOP="$REPO_ROOT/desktop"
BRANDING="$REPO_ROOT/branding"
errors=0
checks=0
stage_tmp=""

fail() { printf 'FAIL  %s\n' "$*" >&2; errors=$((errors + 1)); }
ok() { checks=$((checks + 1)); }
log() { printf 'info  %s\n' "$*"; }

cleanup() {
	if [[ -n "$stage_tmp" ]]; then rm -rf "$stage_tmp"; fi
}
trap cleanup EXIT

require_file() {
	if [[ -f "$1" ]]; then ok; else fail "missing ${1#"$REPO_ROOT"/}"; fi
}

require_executable() {
	if [[ -x "$1" ]]; then ok; else fail "${1#"$REPO_ROOT"/} is not executable"; fi
}

echo "Validating VELCORA build configuration"

for file in \
	"$REPO_ROOT/VERSION" \
	"$REPO_ROOT/.gitignore" \
	"$LIVE_DIR/auto/config" \
	"$DEBIAN/package-lists/velcora-desktop.list.chroot" \
	"$DEBIAN/package-lists/velcora-system.list.chroot" \
	"$DEBIAN/package-lists/velcora-cloud.list.chroot" \
	"$DEBIAN/package-lists/velcora-vm.list.chroot" \
	"$DEBIAN/package-lists/velcora-installer.list.chroot" \
	"$REPO_ROOT/packages/core/velcora-core.list.chroot" \
	"$REPO_ROOT/packages/security/velcora-security.list.chroot" \
	"$REPO_ROOT/packages/monitoring/velcora-monitoring.list.chroot" \
	"$REPO_ROOT/packages/networking/velcora-networking.list.chroot" \
	"$REPO_ROOT/packages/storage/velcora-storage.list.chroot" \
	"$REPO_ROOT/packages/administration/velcora-administration.list.chroot" \
	"$REPO_ROOT/packages/utilities/velcora-utilities.list.chroot" \
	"$DEBIAN/apt/apt.conf" \
	"$DEBIAN/archives/velcora-contrib.list.chroot" \
	"$DEBIAN/archives/velcora-contrib.pref.chroot" \
	"$BOOT/bootloaders/isolinux/isolinux.cfg" \
	"$BOOT/bootloaders/isolinux/menu.cfg" \
	"$BOOT/bootloaders/isolinux/live.cfg.in" \
	"$BOOT/bootloaders/isolinux/stdmenu.cfg" \
	"$BOOT/bootloaders/grub-pc/config.cfg" \
	"$BOOT/bootloaders/grub-pc/grub.cfg" \
	"$BOOT/bootloaders/grub-pc/live-theme/theme.txt" \
	"$BOOT/plymouth/velcora/velcora.plymouth" \
	"$BOOT/plymouth/velcora/velcora.script" \
	"$BOOT/hooks/0100-velcora-branding.hook.chroot" \
	"$BOOT/initramfs/compression.conf" \
	"$DEBIAN/hooks/0200-velcora-installer.hook.chroot" \
	"$DEBIAN/hooks/9900-velcora-trim.hook.chroot" \
	"$DEBIAN/trim/01_nodoc" \
	"$DEBIAN/base/etc/os-release" \
	"$DEBIAN/base/etc/issue" \
	"$DEBIAN/base/usr/lib/os-release" \
	"$DEBIAN/base/etc/default/prometheus-node-exporter" \
	"$DEBIAN/sudoers/90-velcora-live" \
	"$DEBIAN/installer/etc/calamares/settings.conf" \
	"$DEBIAN/installer/etc/calamares/modules/shellprocess.conf" \
	"$DEBIAN/installer/etc/calamares/branding/velcora/branding.desc" \
	"$DEBIAN/installer/etc/calamares/branding/velcora/welcome.png" \
	"$DEBIAN/installer/usr/local/bin/velcora-installer" \
	"$DEBIAN/installer/usr/local/bin/velcora-install-desktop-icon" \
	"$DEBIAN/installer/usr/local/bin/velcora-welcome" \
	"$DEBIAN/installer/usr/local/share/velcora/install-velcora.desktop" \
	"$DEBIAN/installer/usr/share/applications/velcora-installer.desktop" \
	"$DESKTOP/autostart/etc/xdg/autostart/velcora-welcome.desktop" \
	"$DEBIAN/vm/usr/local/bin/velcora-install-guest-additions" \
	"$DEBIAN/sudoers/90-velcora-live" \
	"$DESKTOP/xfce/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml" \
	"$DESKTOP/xfce/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" \
	"$DESKTOP/xfce/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-terminal.xml" \
	"$DESKTOP/xfce/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml" \
	"$DESKTOP/xfce/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" \
	"$DESKTOP/xfce/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-terminal.xml" \
	"$DESKTOP/lightdm/etc/lightdm/lightdm-gtk-greeter.conf.d/50-velcora.conf" \
	"$DESKTOP/gtk-3.0/etc/gtk-3.0/settings.ini" \
	"$DESKTOP/autostart/etc/xdg/autostart/velcora-install-icon.desktop" \
	"$DESKTOP/fonts/etc/fonts/conf.d/60-velcora.conf" \
	"$BRANDING/logo/velcora-logo.svg" \
	"$BRANDING/fonts/inter/InterVariable.ttf" \
	"$BRANDING/wallpapers/velcora_wallpaper_datacenter_core.jpg" \
	"$REPO_ROOT/scripts/build/build-iso.sh" \
	"$REPO_ROOT/scripts/build/stage-live-config.sh" \
	"$REPO_ROOT/scripts/build/render-boot-branding.py" \
	"$REPO_ROOT/scripts/build/sync-branding-assets.py" \
	"$REPO_ROOT/scripts/release/publish-iso.sh"; do
	require_file "$file"
done

for executable in \
	"$LIVE_DIR/auto/config" \
	"$REPO_ROOT/scripts/build/build-iso.sh" \
	"$REPO_ROOT/scripts/build/stage-live-config.sh" \
	"$REPO_ROOT/scripts/release/publish-iso.sh" \
	"$BOOT/hooks/0100-velcora-branding.hook.chroot" \
	"$DEBIAN/hooks/0200-velcora-installer.hook.chroot" \
	"$DEBIAN/hooks/9900-velcora-trim.hook.chroot" \
	"$DEBIAN/installer/usr/local/bin/velcora-installer" \
	"$DEBIAN/installer/usr/local/bin/velcora-install-desktop-icon" \
	"$DEBIAN/installer/usr/local/bin/velcora-welcome" \
	"$DEBIAN/vm/usr/local/bin/velcora-install-guest-additions"; do
	require_executable "$executable"
done

version="$(tr -d '[:space:]' < "$REPO_ROOT/VERSION")"
if [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9.]+)?$ ]]; then
	ok
else
	fail "VERSION '$version' is not a valid version string"
fi

while IFS= read -r script; do
	if bash -n "$script"; then ok; else fail "syntax error in ${script#"$REPO_ROOT"/}"; fi
done < <(find "$REPO_ROOT/scripts" -type f -name '*.sh')

for script in \
	"$LIVE_DIR/auto/config" \
	"$BOOT/hooks/0100-velcora-branding.hook.chroot" \
	"$DEBIAN/hooks/0200-velcora-installer.hook.chroot" \
	"$DEBIAN/hooks/9900-velcora-trim.hook.chroot" \
	"$DEBIAN/installer/usr/local/bin/velcora-installer" \
	"$DEBIAN/installer/usr/local/bin/velcora-install-desktop-icon" \
	"$DEBIAN/vm/usr/local/bin/velcora-install-guest-additions"; do
	if sh -n "$script"; then ok; else fail "syntax error in ${script#"$REPO_ROOT"/}"; fi
done

for script in "$REPO_ROOT"/scripts/build/*.py \
	"$DEBIAN/installer/usr/local/bin/velcora-welcome"; do
	if python3 -c 'import pathlib,sys; compile(pathlib.Path(sys.argv[1]).read_text(), sys.argv[1], "exec")' "$script"; then
		ok
	else
		fail "syntax error in ${script#"$REPO_ROOT"/}"
	fi
done

# --- source layout ---------------------------------------------------------
# Staging must reproduce the live-build tree from the top-level source areas.
stage_tmp="$(mktemp -d)"
if bash "$REPO_ROOT/scripts/build/stage-live-config.sh" \
	--source "$REPO_ROOT" --target "$stage_tmp/live-build" \
	--allow-missing-generated >/dev/null; then
	ok
else
	fail "stage-live-config.sh could not assemble the live-build tree"
fi
for file in \
	"$stage_tmp/live-build/config/apt/apt.conf" \
	"$stage_tmp/live-build/config/archives/velcora-contrib.list.chroot" \
	"$stage_tmp/live-build/config/package-lists/velcora-desktop.list.chroot" \
	"$stage_tmp/live-build/config/bootloaders/isolinux/isolinux.cfg" \
	"$stage_tmp/live-build/config/hooks/normal/0100-velcora-branding.hook.chroot" \
	"$stage_tmp/live-build/config/hooks/normal/0200-velcora-installer.hook.chroot" \
	"$stage_tmp/live-build/config/hooks/normal/9900-velcora-trim.hook.chroot" \
	"$stage_tmp/live-build/config/includes.chroot_before_packages/etc/dpkg/dpkg.cfg.d/01_nodoc" \
	"$stage_tmp/live-build/config/includes.chroot/etc/initramfs-tools/conf.d/zz-velcora-compression.conf" \
	"$stage_tmp/live-build/config/includes.chroot/etc/os-release" \
	"$stage_tmp/live-build/config/includes.chroot/etc/default/prometheus-node-exporter" \
	"$stage_tmp/live-build/config/includes.chroot/etc/sudoers.d/90-velcora-live" \
	"$stage_tmp/live-build/config/includes.chroot/etc/calamares/settings.conf" \
	"$stage_tmp/live-build/config/includes.chroot/usr/local/bin/velcora-installer" \
	"$stage_tmp/live-build/config/includes.chroot/usr/local/bin/velcora-welcome" \
	"$stage_tmp/live-build/config/includes.chroot/usr/share/applications/velcora-installer.desktop" \
	"$stage_tmp/live-build/config/includes.chroot/etc/xdg/autostart/velcora-welcome.desktop" \
	"$stage_tmp/live-build/config/includes.chroot/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" \
	"$stage_tmp/live-build/config/includes.chroot/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-terminal.xml" \
	"$stage_tmp/live-build/config/includes.chroot/usr/share/plymouth/themes/velcora/velcora.script" \
	"$stage_tmp/live-build/config/includes.chroot/usr/share/fonts/truetype/velcora/InterVariable.ttf" \
	"$stage_tmp/live-build/config/includes.chroot/usr/share/fonts/truetype/velcora/JetBrainsMono-Regular.ttf" \
	"$stage_tmp/live-build/config/includes.chroot/usr/share/doc/fonts-jetbrains-mono-velcora/OFL.txt"; do
	if [[ -f "$file" ]]; then ok; else fail "staging did not produce ${file#"$stage_tmp"/}"; fi
done

for category in core security monitoring networking storage administration utilities; do
	staged="$stage_tmp/live-build/config/package-lists/velcora-$category.list.chroot"
	if [[ -s "$staged" ]]; then
		ok
	else
		fail "staging did not produce packages/$category/velcora-$category.list.chroot"
	fi
done

staged_fonts="$stage_tmp/live-build/config/includes.chroot/usr/share/fonts/truetype/velcora"
jetbrains_count="$(find "$staged_fonts" -maxdepth 1 -type f -name 'JetBrainsMono-*.ttf' | wc -l)"
if (( jetbrains_count == 16 )); then
	ok
else
	fail "expected 16 staged JetBrains Mono faces, found $jetbrains_count"
fi
if find "$staged_fonts" -maxdepth 1 -type f -name 'JetBrainsMonoNL-*.ttf' -print -quit | grep -q .; then
	fail "the no-ligature JetBrainsMonoNL family must not be installed"
else
	ok
fi

# --- branding --------------------------------------------------------------
auto_config="$LIVE_DIR/auto/config"
for expected in '--iso-application "Velcora Linux"' '--iso-volume "VELCORA"' \
	'--iso-publisher "Velcora Linux Project"' \
	'--chroot-squashfs-compression-type "xz -Xbcj x86 -b 1M -Xdict-size 100%"'; do
	if grep -qF -- "$expected" "$auto_config"; then
		ok
	else
		fail "auto/config must contain $expected"
	fi
done

# The documentation filter is applied before package install and must be
# removed again by the trim hook, so apt keeps unpacking docs for users.
nodoc="$DEBIAN/trim/01_nodoc"
for expected in 'path-exclude=/usr/share/doc/*' 'path-include=/usr/share/doc/*/copyright'; do
	if grep -qxF -- "$expected" "$nodoc"; then
		ok
	else
		fail "debian/trim/01_nodoc must contain $expected"
	fi
done
trim_hook="$DEBIAN/hooks/9900-velcora-trim.hook.chroot"
if grep -qF 'rm -f /etc/dpkg/dpkg.cfg.d/01_nodoc' "$trim_hook" \
	&& grep -qF 'apt-get clean' "$trim_hook"; then
	ok
else
	fail "the trim hook must delete the dpkg filter and clean the apt cache"
fi
if grep -qF "find /usr/share/doc -type f ! -name 'copyright*'" "$trim_hook" \
	&& grep -qF 'fonts-inter-velcora' "$trim_hook" \
	&& grep -qF 'fonts-jetbrains-mono-velcora' "$trim_hook"; then
	ok
else
	fail "the trim hook must remove leftover package docs but keep copyright and font notices"
fi
if grep -qF "keep_locales='en de fr es it pt nl pl ru zh_CN zh_TW ja ko tr ar'" "$trim_hook"; then
	ok
else
	fail "the trim hook must keep English and the fourteen approved locales"
fi

# Demo and install must be separate boot choices, and the installer entry
# passes velcora.mode=install so the welcome window can skip its dialog.
for boot_config in \
	"$BOOT/bootloaders/isolinux/live.cfg.in" \
	"$BOOT/bootloaders/grub-pc/grub.cfg"; do
	for expected in 'Try Velcora Linux (live demo)' 'Install Velcora Linux' 'velcora.mode=install'; do
		if grep -qF -- "$expected" "$boot_config"; then
			ok
		else
			fail "${boot_config#"$REPO_ROOT"/} must contain $expected"
		fi
	done
done
if grep -qF 'velcora-welcome' \
	"$DESKTOP/autostart/etc/xdg/autostart/velcora-welcome.desktop" \
	&& grep -qF 'in_live_session' "$DEBIAN/installer/usr/local/bin/velcora-welcome"; then
	ok
else
	fail "the welcome window must autostart in the live session only"
fi
if grep -qxF 'greeter-hide-users=true' \
	"$DESKTOP/lightdm/etc/lightdm/lightdm-gtk-greeter.conf.d/50-velcora.conf"; then
	ok
else
	fail "the LightDM greeter must ask for the account name"
fi
if grep -qxF 'COMPRESS=xz' "$BOOT/initramfs/compression.conf"; then
	ok
else
	fail "boot/initramfs/compression.conf must set COMPRESS=xz"
fi

os_release="$DEBIAN/base/etc/os-release"
for expected in 'NAME="Velcora Linux"' 'ID_LIKE=debian' "VERSION_ID=\"$version\""; do
	if grep -qxF "$expected" "$os_release"; then
		ok
	else
		fail "os-release must contain $expected"
	fi
done
if [[ "$(readlink -f "$DEBIAN/base/usr/lib/os-release")" == "$(readlink -f "$os_release")" ]]; then
	ok
else
	fail "debian/base/usr/lib/os-release must resolve to debian/base/etc/os-release"
fi
if grep -qF "Velcora Linux $version" "$DEBIAN/base/etc/issue"; then
	ok
else
	fail "/etc/issue must name Velcora Linux $version"
fi
if grep -qxF 'ARGS="--web.listen-address=127.0.0.1:9100"' \
	"$DEBIAN/base/etc/default/prometheus-node-exporter"; then
	ok
else
	fail "node_exporter must listen on localhost by default"
fi

# Wallpapers: every unique source image ships, and the default is a symlink.
mapfile -t wallpapers < <(
	find "$BRANDING/wallpapers" -maxdepth 1 -type f -name '*.jpg' \
		! -name '* (*' -print | sort
)
if (( ${#wallpapers[@]} == 8 )); then
	ok
else
	fail "expected 8 unique wallpapers in branding/wallpapers, found ${#wallpapers[@]}"
fi
if grep -qF 'DEFAULT_WALLPAPER = "velcora_wallpaper_datacenter_core.jpg"' \
	"$REPO_ROOT/scripts/build/sync-branding-assets.py"; then
	ok
else
	fail "sync-branding-assets.py must default to the datacenter-core wallpaper"
fi

xfce_desktop="$DESKTOP/xfce/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml"
skel_desktop="$DESKTOP/xfce/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml"
for desktop_file in "$xfce_desktop" "$skel_desktop"; do
	if grep -qF '/usr/share/backgrounds/velcora/velcora-default.jpg' "$desktop_file"; then
		ok
	else
		fail "${desktop_file#"$REPO_ROOT"/} must point at the Velcora wallpaper"
	fi
done

# Xfce, GTK and LightDM select the Velcora icon theme and typeface.
for settings in \
	"$DESKTOP/xfce/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" \
	"$DESKTOP/xfce/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml"; do
	if grep -qF '<property name="IconThemeName" type="string" value="Velcora"/>' "$settings"; then
		ok
	else
		fail "${settings#"$REPO_ROOT"/} must select the Velcora icon theme"
	fi
done
if grep -qF 'gtk-icon-theme-name=Velcora' "$DESKTOP/gtk-3.0/etc/gtk-3.0/settings.ini"; then
	ok
else
	fail "GTK settings.ini must select the Velcora icon theme"
fi
if grep -qF 'Inter Variable' "$DESKTOP/gtk-3.0/etc/gtk-3.0/settings.ini"; then
	ok
else
	fail "GTK settings.ini must use the bundled Inter typeface"
fi
if grep -qF '<family>Inter Variable</family>' "$DESKTOP/fonts/etc/fonts/conf.d/60-velcora.conf"; then
	ok
else
	fail "fontconfig must prefer the bundled Inter typeface"
fi

# JetBrains Mono is the terminal typeface only.  Inter stays the desktop font,
# and the terminal channel must not fall back to the system UI font.
for settings in \
	"$DESKTOP/xfce/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-terminal.xml" \
	"$DESKTOP/xfce/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-terminal.xml"; do
	if grep -qF '<property name="font-name" type="string" value="JetBrains Mono 11"/>' "$settings" \
		&& grep -qF '<property name="font-use-system" type="bool" value="false"/>' "$settings"; then
		ok
	else
		fail "${settings#"$REPO_ROOT"/} must select JetBrains Mono 11 with font-use-system disabled"
	fi
	if grep -qF 'Inter' "$settings"; then
		fail "${settings#"$REPO_ROOT"/} must not select the UI typeface"
	else
		ok
	fi
done
for settings in \
	"$DESKTOP/xfce/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" \
	"$DESKTOP/xfce/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml"; do
	if grep -qF '<property name="FontName" type="string" value="Inter Variable 10"/>' "$settings"; then
		ok
	else
		fail "${settings#"$REPO_ROOT"/} must keep Inter Variable as the UI font"
	fi
	if grep -qF 'JetBrains' "$settings"; then
		fail "${settings#"$REPO_ROOT"/} must not select JetBrains Mono"
	else
		ok
	fi
done
if grep -qF 'JetBrains' "$DESKTOP/gtk-3.0/etc/gtk-3.0/settings.ini" \
	|| grep -qF 'JetBrains' "$DESKTOP/fonts/etc/fonts/conf.d/60-velcora.conf"; then
	fail "JetBrains Mono must be selected by xfce4-terminal only"
else
	ok
fi

greeter="$DESKTOP/lightdm/etc/lightdm/lightdm-gtk-greeter.conf.d/50-velcora.conf"
for expected in 'background=/usr/share/backgrounds/velcora/velcora-default.jpg' \
	'icon-theme-name=Velcora' \
	'greeter-hide-users=true' \
	'default-user-image=/usr/share/velcora/logo/velcora-logo.png'; do
	if grep -qxF "$expected" "$greeter"; then
		ok
	else
		fail "LightDM greeter drop-in must contain $expected"
	fi
done

# Plymouth: theme source, animation frames and default-theme hook.
plymouth_theme="$BOOT/plymouth/velcora/velcora.plymouth"
plymouth_script="$BOOT/plymouth/velcora/velcora.script"
if grep -qx 'ModuleName=script' "$plymouth_theme"; then
	ok
else
	fail "Plymouth theme must use the script module"
fi
if grep -qF 'ScriptFile=/usr/share/plymouth/themes/velcora/velcora.script' "$plymouth_theme"; then
	ok
else
	fail "Plymouth theme must point at velcora.script"
fi
for expected in 'frame_count = 24' 'background.png' 'logo_files' \
	'Plymouth.SetBootProgressFunction' 'progress-fill.png'; do
	if grep -qF "$expected" "$plymouth_script"; then
		ok
	else
		fail "Plymouth script must contain $expected"
	fi
done

plymouth_hook="$BOOT/hooks/0100-velcora-branding.hook.chroot"
for expected in 'plymouth-set-default-theme "$theme"' \
	'grep -qx "Theme=$theme" /etc/plymouth/plymouthd.conf' \
	'update-initramfs -u -k all'; do
	if grep -qF "$expected" "$plymouth_hook"; then
		ok
	else
		fail "Plymouth hook must contain $expected"
	fi
done

# Generated artwork is checked when it has been rendered.
if [[ -d "$GENERATED" ]]; then
	backgrounds="$GENERATED/includes.chroot/usr/share/backgrounds/velcora"
	if [[ -L "$backgrounds/velcora-default.jpg" ]]; then
		ok
	else
		fail "generated default wallpaper must be a symlink"
	fi
	if [[ "$(readlink "$backgrounds/velcora-default.jpg" 2>/dev/null)" == 'velcora_wallpaper_datacenter_core.jpg' ]]; then
		ok
	else
		fail "generated default wallpaper must point at datacenter-core"
	fi
	if [[ "$(find "$backgrounds" -maxdepth 1 -type f -name '*.jpg' | wc -l)" -eq 8 ]]; then
		ok
	else
		fail "generated wallpaper directory must contain 8 unique wallpapers"
	fi
	if grep -qx 'Name=Velcora' "$GENERATED/includes.chroot/usr/share/icons/Velcora/index.theme"; then
		ok
	else
		fail "generated Velcora icon theme is missing or misnamed"
	fi
	frames="$GENERATED/includes.chroot/usr/share/plymouth/themes/velcora"
	if [[ "$(find "$frames" -maxdepth 1 -type f -name 'logo-*.png' | wc -l)" -eq 24 ]]; then
		ok
	else
		fail "generated Plymouth theme must contain 24 animation frames"
	fi
	if [[ -f "$frames/background.png" ]]; then ok; else fail "generated Plymouth background is missing"; fi
	splash="$GENERATED/bootloaders/splash.svg"
	if grep -qF 'class="whale-rig"' "$splash"; then
		ok
	else
		fail "generated boot splash must contain the whale artwork"
	fi
else
	log "build/generated is absent; skipping generated-artwork checks (make iso renders it)"
fi

# --- boot menus ------------------------------------------------------------
if grep -qF 'menu title Velcora Linux @VERSION@' "$BOOT/bootloaders/isolinux/menu.cfg"; then
	ok
else
	fail "isolinux menu.cfg must use a Velcora menu title"
fi
if grep -qF 'Start Velcora Linux' "$BOOT/bootloaders/isolinux/live.cfg.in"; then
	ok
else
	fail "isolinux live.cfg.in must use Velcora entries"
fi
if grep -qF 'Start Velcora Linux' "$BOOT/bootloaders/grub-pc/grub.cfg"; then
	ok
else
	fail "GRUB grub.cfg must use Velcora entries"
fi
if grep -Rqi 'Debian GNU/Linux' "$BOOT/bootloaders"; then
	fail "bootloader overrides still contain Debian branding"
else
	ok
fi

bootloader_isolinux="$BOOT/bootloaders/isolinux/isolinux.cfg"
bootloader_grub="$BOOT/bootloaders/grub-pc/config.cfg"
if grep -qx 'timeout 300' "$bootloader_isolinux"; then
	ok
else
	fail "isolinux.cfg must boot the default entry after 30 seconds (timeout 300)"
fi
if grep -qx 'set timeout=30' "$bootloader_grub"; then
	ok
else
	fail "grub config.cfg must boot the default entry after 30 seconds (set timeout=30)"
fi

# --- VirtualBox guest integration -----------------------------------------
vm_list="$DEBIAN/package-lists/velcora-vm.list.chroot"
for package in virtualbox-guest-utils virtualbox-guest-x11; do
	if grep -qx "$package" "$vm_list"; then
		ok
	else
		fail "velcora-vm.list.chroot must list $package"
	fi
done
if grep -q 'unstable contrib' "$DEBIAN/archives/velcora-contrib.list.chroot"; then
	ok
else
	fail "velcora-contrib.list.chroot must point at unstable/contrib"
fi
if grep -q 'Pin-Priority: 990' "$DEBIAN/archives/velcora-contrib.pref.chroot"; then
	ok
else
	fail "velcora-contrib.pref.chroot must pin the VirtualBox guest packages"
fi

# --- Calamares installer ---------------------------------------------------
installer_list="$DEBIAN/package-lists/velcora-installer.list.chroot"
for package in calamares calamares-settings-debian; do
	if grep -qx "$package" "$installer_list"; then
		ok
	else
		fail "velcora-installer.list.chroot must list $package"
	fi
done
if grep -qx 'branding: velcora' "$DEBIAN/installer/etc/calamares/settings.conf"; then
	ok
else
	fail "Calamares settings.conf must use branding: velcora"
fi
if grep -qx '  - shellprocess' "$DEBIAN/installer/etc/calamares/settings.conf"; then
	ok
else
	fail "Calamares settings.conf must run the shellprocess cleanup"
fi
if grep -qF 'rm -f /etc/sudoers.d/90-velcora-live' \
	"$DEBIAN/installer/etc/calamares/modules/shellprocess.conf"; then
	ok
else
	fail "Calamares shellprocess.conf must remove the live sudoers file"
fi
if grep -qF 'NOPASSWD: ALL' "$DEBIAN/sudoers/90-velcora-live"; then
	ok
else
	fail "live sudoers file must grant passwordless sudo"
fi
if grep -qF 'rm -rf /etc/calamares/branding/debian' \
	"$DEBIAN/hooks/0200-velcora-installer.hook.chroot"; then
	ok
else
	fail "the Calamares hook must drop Debian's installer branding"
fi
if grep -qF 'componentName: velcora' \
	"$DEBIAN/installer/etc/calamares/branding/velcora/branding.desc"; then
	ok
else
	fail "Calamares branding.desc must declare componentName: velcora"
fi
if grep -qF 'Name=Install Velcora' \
	"$DEBIAN/installer/usr/local/share/velcora/install-velcora.desktop"; then
	ok
else
	fail "the live desktop launcher must be named Install Velcora"
fi

# --- apt retries -----------------------------------------------------------
if grep -q 'Acquire::Retries' "$DEBIAN/apt/apt.conf"; then
	ok
else
	fail "debian/apt/apt.conf must set Acquire::Retries for transient network failures"
fi

if command -v shellcheck >/dev/null 2>&1; then
	if shellcheck -S warning "$REPO_ROOT"/scripts/build/*.sh "$LIVE_DIR/auto/config"; then
		ok
	else
		fail "shellcheck reported problems"
	fi
fi

declare -A seen=()
for list in "$DEBIAN/package-lists"/*.list.chroot "$REPO_ROOT"/packages/*/*.list.chroot; do
	[[ -e "$list" ]] || continue
	while IFS= read -r package || [[ -n "$package" ]]; do
		[[ -z "$package" || "$package" == \#* ]] && continue
		if [[ ! "$package" =~ ^[a-z0-9][a-z0-9+.-]*$ ]]; then
			fail "${list##*/}: invalid package name '$package'"
		elif [[ -n "${seen[$package]:-}" ]]; then
			fail "package '$package' is listed in both ${seen[$package]##*/} and ${list##*/}"
		else
			seen[$package]="${list##*/}"
			ok
		fi
	done < "$list"
done

for pattern in '/build/work/' '/build/output/' '/build/generated/'; do
	if grep -qxF "$pattern" "$REPO_ROOT/.gitignore"; then
		ok
	else
		fail ".gitignore does not ignore $pattern"
	fi
done

if (( errors > 0 )); then
	printf '\n%d check(s) failed\n' "$errors" >&2
	exit 1
fi
printf 'OK — %d checks passed\n' "$checks"
