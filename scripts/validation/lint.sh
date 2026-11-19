#!/usr/bin/env bash
## Lint all shell and Python sources.
##
## Uses host shellcheck when available and otherwise a disposable Debian
## container, so `make lint` works before the host tooling is installed.

set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IMAGE="${VELCORA_BUILDER_IMAGE:-debian:trixie}"
DOCKER="${DOCKER:-docker}"

die() { printf 'lint: %s\n' "$*" >&2; exit 1; }

mapfile -t shell_files < <(
	find "$REPO_ROOT/scripts" "$REPO_ROOT/testing" -type f -name '*.sh' -print
	find "$REPO_ROOT/boot/hooks" "$REPO_ROOT/debian/hooks" -type f -name '*.hook.chroot' -print
	printf '%s\n' "$REPO_ROOT/build/live-build/auto/config"
)
mapfile -t python_files < <(
	find "$REPO_ROOT/scripts" "$REPO_ROOT/testing" -type f -name '*.py' -print
)
# Helpers in the installer and VM trees have no file extension; sort them by
# their shebang instead of assuming they are shell scripts.
while IFS= read -r helper; do
	if head -n 1 "$helper" | grep -Eq '^#!.*python'; then
		python_files+=("$helper")
	else
		shell_files+=("$helper")
	fi
done < <(
	find "$REPO_ROOT/debian/installer/usr/local/bin" \
		"$REPO_ROOT/debian/vm/usr/local/bin" -type f -print
	printf '%s\n' "$REPO_ROOT/installer/branding-package/postinst"
)

(( ${#shell_files[@]} > 0 )) || die "no shell scripts found"

if command -v shellcheck >/dev/null 2>&1; then
	shellcheck -S warning "${shell_files[@]}"
else
	command -v "$DOCKER" >/dev/null 2>&1 \
		|| die "shellcheck is not installed and $DOCKER is unavailable"
	printf 'info  shellcheck is absent; linting inside %s\n' "$IMAGE"
	relative=()
	for file in "${shell_files[@]}"; do
		relative+=("${file#"$REPO_ROOT"/}")
	done
	"$DOCKER" run --rm -v "$REPO_ROOT:/src:ro" -w /src "$IMAGE" bash -c '
		set -Eeuo pipefail
		export DEBIAN_FRONTEND=noninteractive
		apt-get update -qq
		apt-get install -y -qq --no-install-recommends shellcheck >/dev/null
		shellcheck -S warning "$@"
	' _ "${relative[@]}"
fi

for file in "${python_files[@]}"; do
	python3 -c 'import pathlib, sys; compile(pathlib.Path(sys.argv[1]).read_text(), sys.argv[1], "exec")' "$file"
done

printf 'OK — %d shell files and %d Python files linted\n' \
	"${#shell_files[@]}" "${#python_files[@]}"
