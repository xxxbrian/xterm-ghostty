#!/bin/sh
set -eu

repo="${REPO:-xxxbrian/xterm-ghostty}"
prefix="${PREFIX:-$HOME/.terminfo}"
tag="${TAG:-latest}"

if [ "$tag" = "latest" ]; then
  url="https://github.com/$repo/releases/latest/download/xterm-ghostty.terminfo"
else
  url="https://github.com/$repo/releases/download/$tag/xterm-ghostty.terminfo"
fi

tmp="$(mktemp)"
cleanup() {
  rm -f "$tmp"
}
trap cleanup EXIT HUP INT TERM

curl -fsSL "$url" -o "$tmp"
mkdir -p "$prefix"
tic -x -o "$prefix" "$tmp"
TERMINFO="$prefix" infocmp -x xterm-ghostty >/dev/null

printf '%s\n' "installed xterm-ghostty terminfo to $prefix"
