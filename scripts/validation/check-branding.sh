#!/usr/bin/env bash
## Verify that the source branding assets are present and usable.
## Run by `make test` and by CI; does not need an ISO or root.

set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BRANDING="$REPO_ROOT/branding"
errors=0
checks=0

fail() { printf 'FAIL  %s\n' "$*" >&2; errors=$((errors + 1)); }
ok() { checks=$((checks + 1)); }
log() { printf 'info  %s\n' "$*"; }

require_file() {
	if [[ -s "$1" ]]; then
		ok
	else
		fail "missing or empty: ${1#"$REPO_ROOT"/}"
	fi
}

echo "Checking VELCORA branding assets"

for file in \
	"$BRANDING/logo/velcora-logo.svg" \
	"$BRANDING/colours/palette.css" \
	"$BRANDING/colours/palette.json" \
	"$BRANDING/colours/README.md" \
	"$BRANDING/fonts/inter/InterVariable.ttf" \
	"$BRANDING/fonts/inter/LICENSE.txt" \
	"$BRANDING/icons/README.md"; do
	require_file "$file"
done

if grep -Eq '<image|data:image' "$BRANDING/logo/velcora-logo.svg"; then
	fail "logo SVG embeds a raster image; keep it vector"
else
	ok
fi

if python3 -m json.tool "$BRANDING/colours/palette.json" >/dev/null 2>&1; then
	ok
else
	fail "branding/colours/palette.json is not valid JSON"
fi

mapfile -t wallpapers < <(
	find "$BRANDING/wallpapers" -maxdepth 1 -type f -name '*.jpg' ! -name '* (*' -print | sort
)
if (( ${#wallpapers[@]} == 8 )); then
	ok
else
	fail "expected 8 unique wallpapers, found ${#wallpapers[@]}"
fi

for wallpaper in "${wallpapers[@]}"; do
	magic="$(od -An -N3 -tx1 "$wallpaper" | tr -d ' \n')"
	if [[ "$magic" == "ffd8ff" ]]; then
		ok
	else
		fail "${wallpaper##*/} is not a JPEG image"
	fi
done

duplicates="$(find "$BRANDING/wallpapers" -maxdepth 1 -type f -name '* (*' -print)"
if [[ -n "$duplicates" ]]; then
	log "duplicate-named wallpaper kept for now: ${duplicates##*/}"
fi

for set in panel taskbar; do
	mapfile -t svgs < <(find "$BRANDING/icons/$set" -maxdepth 1 -type f -name '*.svg' -print | sort)
	if (( ${#svgs[@]} > 0 )); then
		ok
	else
		fail "no SVG icons in branding/icons/$set"
	fi
	for svg in "${svgs[@]}"; do
		if [[ -f "${svg%.svg}.png" ]]; then
			ok
		else
			fail "missing PNG for ${svg##*/}"
		fi
	done
done

mapfile -t fonts < <(find "$BRANDING/fonts/jetbrains-mono" -type f \( -name '*.ttf' -o -name '*.woff2' \) -print)
if (( ${#fonts[@]} > 0 )); then
	ok
else
	fail "no JetBrains Mono font files under branding/fonts/jetbrains-mono"
fi
if find "$BRANDING/fonts/jetbrains-mono" -maxdepth 1 -type f \
	\( -name 'LICENSE*' -o -name 'OFL*' -o -name 'COPYING*' \) -print -quit | grep -q .; then
	ok
else
	fail "JetBrains Mono licence file is missing"
fi

if (( errors > 0 )); then
	printf '\n%d branding check(s) failed\n' "$errors" >&2
	exit 1
fi
printf 'OK — %d branding checks passed\n' "$checks"
