#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GHOSTTY_REPO="${GHOSTTY_REPO:-https://github.com/ghostty-org/ghostty.git}"
GHOSTTY_REF="${GHOSTTY_REF:-main}"
ZIG_VERSION="${ZIG_VERSION:-0.15.2}"
ZIG_TARGET="${ZIG_TARGET:-}"

tmp_dirs=()
tmp_files=()

cleanup() {
  for path in "${tmp_dirs[@]}"; do
    rm -rf "$path"
  done
  for path in "${tmp_files[@]}"; do
    rm -f "$path"
  done
}
trap cleanup EXIT

if [[ -n "${GHOSTTY_DIR:-}" ]]; then
  ghostty_dir="$GHOSTTY_DIR"
else
  clone_dir="$(mktemp -d)"
  tmp_dirs+=("$clone_dir")
  git clone --depth=1 --filter=blob:none --branch "$GHOSTTY_REF" "$GHOSTTY_REPO" "$clone_dir/ghostty"
  ghostty_dir="$clone_dir/ghostty"
fi

if [[ ! -f "$ghostty_dir/src/terminfo/ghostty.zig" ]]; then
  echo "error: Ghostty source tree not found at $ghostty_dir" >&2
  exit 1
fi

zig_cmd=(zig)
if command -v mise >/dev/null 2>&1 && mise exec "zig@$ZIG_VERSION" -- zig version >/dev/null 2>&1; then
  zig_cmd=(mise exec "zig@$ZIG_VERSION" -- zig)
fi

actual_zig_version="$("${zig_cmd[@]}" version)"
if [[ "$actual_zig_version" != "$ZIG_VERSION" ]]; then
  echo "error: expected Zig $ZIG_VERSION, got $actual_zig_version" >&2
  exit 1
fi

source_commit="$(git -C "$ghostty_dir" rev-parse HEAD)"
source_short_commit="$(git -C "$ghostty_dir" rev-parse --short=12 HEAD)"
generated_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
terminfo_tmp="$(mktemp)"
generator_dir="$(mktemp -d)"
generator_tmp="$generator_dir/generate.zig"
tmp_dirs+=("$generator_dir")
tmp_files+=("$terminfo_tmp")

cat > "$generator_tmp" <<'ZIG'
const std = @import("std");
const ghostty = @import("ghostty_terminfo").ghostty;

pub fn main() !void {
    var buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writerStreaming(&buffer);
    try ghostty.encode(&stdout_writer.interface);
    try stdout_writer.end();
}
ZIG

zig_run_args=(run)
if [[ -n "$ZIG_TARGET" ]]; then
  zig_run_args+=(-target "$ZIG_TARGET")
fi
zig_run_args+=(
  --dep ghostty_terminfo
  -Mroot="$generator_tmp"
  -Mghostty_terminfo="$ghostty_dir/src/terminfo/ghostty.zig"
)

"${zig_cmd[@]}" "${zig_run_args[@]}" > "$terminfo_tmp"

validate_dir="$(mktemp -d)"
tmp_dirs+=("$validate_dir")
tic -x -o "$validate_dir" "$terminfo_tmp"
TERMINFO="$validate_dir" infocmp -x xterm-ghostty >/dev/null

target="$ROOT/xterm-ghostty.terminfo"
if [[ -f "$target" ]] && cmp -s "$terminfo_tmp" "$target"; then
  echo "xterm-ghostty.terminfo is already current at Ghostty $source_short_commit"
  exit 0
fi

cp "$terminfo_tmp" "$target"
cat > "$ROOT/metadata.json" <<JSON
{
  "source": {
    "repository": "$GHOSTTY_REPO",
    "ref": "$GHOSTTY_REF",
    "commit": "$source_commit",
    "short_commit": "$source_short_commit"
  },
  "generator": {
    "command": "zig run --dep ghostty_terminfo -Mroot=<generator> -Mghostty_terminfo=<ghostty>/src/terminfo/ghostty.zig",
    "zig_version": "$actual_zig_version",
    "zig_target": "$ZIG_TARGET",
    "generated_at": "$generated_at"
  }
}
JSON

echo "updated xterm-ghostty.terminfo from Ghostty $source_short_commit"
