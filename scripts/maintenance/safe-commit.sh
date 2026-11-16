#!/usr/bin/env bash
## Commit and push the working tree after VELCORA safety checks.
##
## Usage: scripts/maintenance/safe-commit.sh "type(scope): summary"
##
## Refuses to commit when:
##   - the message does not follow the project commit format;
##   - anything under .opencode-local/ or feedback/ is staged;
##   - a staged file is larger than 5 MiB;
##   - a staged text file contains the current user's home path.

set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

MAX_BYTES=$((5 * 1024 * 1024))
HOME_PATH="/home/$(id -un)"

die() {
	printf 'safe-commit: %s\n' "$*" >&2
	exit 1
}

(( $# == 1 )) || die 'usage: safe-commit.sh "type(scope): summary"'
message="$1"

if [[ ! "$message" =~ ^(feat|fix|docs|build|chore)\([a-z0-9-]+\):\ .+ ]]; then
	die 'message must look like "type(scope): summary" (feat|fix|docs|build|chore)'
fi

git add -A

if git diff --cached --quiet; then
	printf 'safe-commit: nothing to commit\n'
	exit 0
fi

for private in .opencode-local feedback; do
	if ! git diff --cached --quiet -- "$private"; then
		die "$private/ is staged; it is private and must never be committed"
	fi
done

while IFS= read -r -d '' path; do
	size="$(git cat-file -s ":$path")"
	if (( size > MAX_BYTES )); then
		die "staged file exceeds 5 MiB: $path ($size bytes)"
	fi
done < <(git diff --cached --name-only -z --diff-filter=ACMR)

if git grep --cached -I -n -F -e "$HOME_PATH" -- .; then
	die "a staged text file contains the home path $HOME_PATH"
fi

git commit -m "$message"

if ! git push origin main; then
	printf 'safe-commit: push rejected, rebasing once\n' >&2
	git pull --rebase origin main || die 'rebase failed; resolve the conflict manually'
	git push origin main
fi
