# xterm-ghostty

Automatically updated `xterm-ghostty` terminfo source generated from
[Ghostty](https://github.com/ghostty-org/ghostty).

This repository mirrors Ghostty's upstream terminfo definition. Releases are
created only when the generated terminfo text changes.

## Install

With `curl`:

```sh
mkdir -p ~/.terminfo
curl -fsSL https://github.com/xxxbrian/xterm-ghostty/releases/latest/download/xterm-ghostty.terminfo \
  | tic -x -o ~/.terminfo -
```

With `wget`:

```sh
mkdir -p ~/.terminfo
wget -qO- https://github.com/xxxbrian/xterm-ghostty/releases/latest/download/xterm-ghostty.terminfo \
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
calls its `encode()` method. This avoids depending on Ghostty's full build graph.

The output is validated by compiling it with `tic -x` and checking that
`infocmp -x xterm-ghostty` can read the resulting database.
