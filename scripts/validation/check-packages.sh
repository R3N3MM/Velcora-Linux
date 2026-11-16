#!/usr/bin/env bash
## Resolve every VELCORA package list inside a Debian trixie container.
##
## Mirrors the build's archive setup: trixie main/contrib plus the pinned
## unstable/contrib source used only for the VirtualBox guest userspace
## packages. Nothing is installed on the host.

set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IMAGE="${VELCORA_BUILDER_IMAGE:-debian:trixie}"
DOCKER="${DOCKER:-docker}"

die() { printf 'check-packages: %s\n' "$*" >&2; exit 1; }

command -v "$DOCKER" >/dev/null 2>&1 || die "$DOCKER is required"
"$DOCKER" info >/dev/null 2>&1 || die "cannot connect to the Docker daemon"

shopt -s nullglob
lists=("$REPO_ROOT"/debian/package-lists/*.list.chroot)
(( ${#lists[@]} > 0 )) || die "no package lists found"

count="$(sed -e 's/#.*//' "${lists[@]}" | awk 'NF { n++ } END { print n + 0 }')"
(( count > 0 )) || die "the package lists do not contain any package names"

printf 'info  resolving %d packages in %s\n' "$count" "$IMAGE"

"$DOCKER" run --rm -i -v "$REPO_ROOT:/src:ro" "$IMAGE" bash -s <<'CONTAINER'
set -Eeuo pipefail
export DEBIAN_FRONTEND=noninteractive

sources=/etc/apt/sources.list.d/debian.sources
if [[ -f "$sources" ]]; then
	sed -i 's/^Components: .*/Components: main contrib non-free non-free-firmware/' "$sources"
fi

printf '%s\n' 'deb http://deb.debian.org/debian unstable contrib' \
	> /etc/apt/sources.list.d/velcora-contrib.list
cp /src/debian/archives/velcora-contrib.pref.chroot \
	/etc/apt/preferences.d/velcora-contrib

apt-get -o Acquire::Retries=3 update -qq

mapfile -t packages < <(
	sed -e 's/#.*//' /src/debian/package-lists/*.list.chroot |
		awk 'NF { print $1 }'
)
(( ${#packages[@]} > 0 ))

if ! apt-get install --simulate --no-install-recommends \
	-o Acquire::Retries=3 "${packages[@]}" >/tmp/resolve.log 2>&1; then
	tail -n 40 /tmp/resolve.log
	exit 1
fi

printf 'OK — %d package lists resolve in trixie\n' "$(ls /src/debian/package-lists/*.list.chroot | wc -l)"
CONTAINER
