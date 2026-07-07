# xterm-ghostty

Automatically updated `xterm-ghostty` terminfo source generated from
[Ghostty](https://github.com/ghostty-org/ghostty).

This repository mirrors Ghostty's upstream terminfo definition. Releases are
created only when the generated terminfo text changes.

## Install

One command:

```sh
curl -fsSL https://raw.githubusercontent.com/xxxbrian/xterm-ghostty/main/setup.sh | sh
```

The script installs the latest released `xterm-ghostty.terminfo` into
`~/.terminfo`.

Direct from the latest release:

```sh
mkdir -p ~/.terminfo
curl -fsSL https://github.com/xxxbrian/xterm-ghostty/releases/latest/download/xterm-ghostty.terminfo \
  | tic -x -o ~/.terminfo -
```

Verify:

```sh
infocmp -x xterm-ghostty
```

## Files

- `xterm-ghostty.terminfo`: terminfo source generated from Ghostty.
- `metadata.json`: upstream commit and generator information for the current file.

## Source

The generator imports Ghostty's `src/terminfo/ghostty.zig` as a Zig module and
calls its `encode()` method through this repository's build step:

```sh
zig build generate -Dghostty-src=/path/to/ghostty
```

This avoids depending on Ghostty's full build graph.

The output is validated by compiling it with `tic -x` and checking that
`infocmp -x xterm-ghostty` can read the resulting database.
