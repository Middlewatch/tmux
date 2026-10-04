# Pane frames

The window option `pane-border-frame` (fork patch) frames panes: `outer`
adds a border along the window edge so panes touching the edge are closed
on that side. Dividers between panes stay shared as upstream, so the frame
costs one row or column on each window edge and nothing between panes. An
`all` mode that gave every pane its own frame with a gap column between
neighbours was built and removed; the owner preferred the tighter shared
dividers.

## Sub-features

- `frame-off` reproduces upstream: shared single dividers, no edge borders.
- `frame-outer` closes every pane along the window edge, dividers shared.
- `frame-status` lets a pane status line stand in for the frame on its side.

## How to get to it (user POV)

- `set -g pane-border-frame outer` (or `off`) in the config or at the
  prompt; existing windows refresh at once.
- Split panes with `prefix %` / `prefix "` or `split-window -h` / `-v`.

## Driving it with tmuxlab

Preconditions:

- Lab up with the user's config at 80x24 (`frame: outer, lines: single`).
- Two splits: `bin/tmuxlab cmd split-window -h` then
  `bin/tmuxlab cmd split-window -v`, then `sleep 0.3`.

- **Geometry.** Run `bin/tmuxlab geom`. Three panes: `%0 x=1 y=1 w=39 h=21`,
  `%1 x=41 y=1 w=38 h=10`, `%2 x=41 y=12 w=38 h=10`. Column 40 is the shared
  divider between `%0` and the right column; window row 11 (map row 12) is
  the shared divider between `%1` and `%2`.
- **Map.** Run `bin/tmuxlab map`. Row 1 reads `┌───┬───┐` across the width,
  rows 2 to 22 read `│...│...│` with a single `│` at column 40, row 12
  carries `├───┤` in the right half, and row 23 reads `└───┴───┘`. No `#`
  anywhere.
- **Off.** Run `bin/tmuxlab cmd set -g pane-border-frame off`, `sleep 0.3`,
  `map`. Upstream look: `%0 x=0`, no frame at the window edges. Set it back
  to `outer` afterwards.
- **Status line.** Run `bin/tmuxlab cmd set -g pane-border-status top`,
  `sleep 0.3`, `map`. The top frame row (map row 1) and the divider row 12
  carry each pane's status text and keep their corners; `geom` is unchanged
  (`%0 y=1`, `%1 y=1`, `%2 y=12`). Current behaviour, not a pass criterion:
  the bottom frame row (map row 23) is drawn with `fill-character` (`#`)
  while the status is on top, because the redraw skips a pane's bottom row
  on the assumption that a pane below owns it. Reset with
  `bin/tmuxlab cmd set -g pane-border-status off`.
- **Proof.** Run `bin/tmuxlab proof pane-frames` and cite the path.

## Gotchas

- `geom`'s pane rectangles exclude the frame; the frame is at `x-1`,
  `right+1`, `y-1`, `bottom+1`.
- The map's rows are client rows: with the user's config the status line
  is row 0 and window row N is map row N+1.
- A pane that cannot fit its insets keeps its size and overlaps; keep lab
  windows at least 80x24 for three panes.
- `select-layout even-*` can leave cells overflowing when the frames do not
  fit, as upstream does for too-small windows; that is a known rough edge,
  not a regression.
