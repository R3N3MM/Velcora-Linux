#!/usr/bin/env bash
## Static checks for the VELCORA build configuration.
## Run before an ISO build; used by CI and `make validate`.

set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LIVE_DIR="$REPO_ROOT/build/live-build"
PACKAGE_DIR="$LIVE_DIR/config/package-lists"
errors=0
checks=0

fail() { printf 'FAIL  %s\n' "$*" >&2; errors=$((errors + 1)); }
ok() { checks=$((checks + 1)); }

require_file() {
	if [[ -f "$1" ]]; then ok; else fail "missing $1"; fi
}

echo "Validating VELCORA build configuration"

for file in \
	"$REPO_ROOT/VERSION" \
	"$LIVE_DIR/auto/config" \
	"$PACKAGE_DIR/velcora-desktop.list.chroot" \
	"$PACKAGE_DIR/velcora-system.list.chroot" \
	"$PACKAGE_DIR/velcora-cloud.list.chroot" \
	"$PACKAGE_DIR/velcora-vm.list.chroot" \
	"$LIVE_DIR/config/apt/apt.conf" \
	"$LIVE_DIR/config/includes.chroot/usr/local/bin/velcora-install-guest-additions" \
	"$REPO_ROOT/scripts/build/build-iso.sh" \
	"$REPO_ROOT/scripts/release/publish-iso.sh"; do
	require_file "$file"
done

[[ -x "$LIVE_DIR/auto/config" ]] || fail "auto/config is not executable"
[[ -x "$REPO_ROOT/scripts/build/build-iso.sh" ]] || fail "build-iso.sh is not executable"
[[ -x "$REPO_ROOT/scripts/release/publish-iso.sh" ]] || fail "publish-iso.sh is not executable"
[[ -x "$LIVE_DIR/config/includes.chroot/usr/local/bin/velcora-install-guest-additions" ]] \
	|| fail "velcora-install-guest-additions is not executable"

version="$(tr -d '[:space:]' < "$REPO_ROOT/VERSION")"
if [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9.]+)?$ ]]; then
	ok
else
	fail "VERSION '$version' is not a valid version string"
fi

while IFS= read -r script; do
	if bash -n "$script"; then ok; else fail "syntax error in ${script#"$REPO_ROOT"/}"; fi
done < <(find "$REPO_ROOT/scripts" -type f -name '*.sh')

if sh -n "$LIVE_DIR/auto/config"; then ok; else fail "syntax error in auto/config"; fi

guest_additions_helper="$LIVE_DIR/config/includes.chroot/usr/local/bin/velcora-install-guest-additions"
if sh -n "$guest_additions_helper"; then ok; else fail "syntax error in velcora-install-guest-additions"; fi
if grep -q 'VBoxLinuxAdditions.run' "$guest_additions_helper"; then
	ok
else
	fail "velcora-install-guest-additions must run VBoxLinuxAdditions.run"
fi

if grep -q 'Acquire::Retries' "$LIVE_DIR/config/apt/apt.conf"; then
	ok
else
	fail "config/apt/apt.conf must set Acquire::Retries for transient network failures"
fi

bootloader_isolinux="$LIVE_DIR/config/bootloaders/isolinux/isolinux.cfg"
bootloader_grub="$LIVE_DIR/config/bootloaders/grub-pc/config.cfg"
require_file "$bootloader_isolinux"
require_file "$bootloader_grub"
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

if command -v shellcheck >/dev/null 2>&1; then
	if shellcheck -S warning "$REPO_ROOT"/scripts/build/*.sh "$LIVE_DIR/auto/config"; then
		ok
	else
		fail "shellcheck reported problems"
	fi
fi

declare -A seen=()
for list in "$PACKAGE_DIR"/*.list.chroot; do
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

for pattern in '/build/work/' '/build/output/'; do
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
