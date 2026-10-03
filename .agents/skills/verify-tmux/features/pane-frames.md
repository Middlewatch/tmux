# Pane frames

The window option `pane-border-frame` (fork patch) frames panes: `outer`
adds a border along the window edge so panes touching the edge are closed
on that side; `all` gives every pane its own four-sided frame so the
active frame highlights all round. With `all`, side-by-side frames are
separated by one gap column drawn as a plain blank in `pane-border-style`,
and stacked frames sit on adjacent rows with no gap row, so the visible
spacing between frames is about the same both ways on a 2:1 cell font.

## Sub-features

- `frame-off` reproduces upstream: shared single dividers, no edge borders.
- `frame-outer` closes every pane along the window edge, dividers shared.
- `frame-all-columns` puts frame, gap column, frame between side-by-side
  panes.
- `frame-all-rows` puts the lower pane's top frame directly under the upper
  pane's bottom frame, no gap row.
- `frame-all-gap-style` draws the gap column as a blank with the default
  border style (no `fill-character` background).
- `frame-status` lets a pane status line stand in for the frame on its side.

## How to get to it (user POV)

- `set -g pane-border-frame all` (or `outer`, `off`) in the config or at
  the prompt; existing windows refresh at once.
- Split panes with `prefix %` / `prefix "` or `split-window -h` / `-v`.

## Driving it with tmuxlab

Preconditions:

- Lab up with the user's config at 80x24 (`frame: all, lines: heavy`).
- Two splits: `bin/tmuxlab cmd split-window -h` then
  `bin/tmuxlab cmd split-window -v`, then `sleep 0.3`.

- **Geometry.** Run `bin/tmuxlab geom`. Three panes: `%0 x=1 y=1 w=38 h=21`,
  `%1 x=42 y=1 w=37 h=9`, `%2 x=42 y=12 w=37 h=10`. Column 40 (the layout
  divider) is the gap; `%2` starts one row below `%1`'s bottom frame row.
- **Columns.** Run `bin/tmuxlab map`. Map rows 2 to 22 read
  `┃...┃ ┃...┃` with a plain space at column 40 between the two frames.
- **Rows.** In the same map, row 11 ends `┗━━━┛` for `%1` and row 12 starts
  `┏━━━┓` for `%2` in the right column, with no blank row between them.
- **Gap style.** The map shows no `#` anywhere: the gap column is a blank
  with default background. To see the regression this guards, run
  `bin/tmuxlab cmd set -g fill-character '#[bg=red] '` and `map` again: the
  gap must still show a space, not `#`. Reset with
  `bin/tmuxlab cmd set -gu fill-character`.
- **Outer.** Run `bin/tmuxlab cmd set -g pane-border-frame outer`,
  `sleep 0.3`, `map`. One shared divider column between left and right, one
  shared divider row between `%1` and `%2`, and a frame along all four
  window edges. `geom` shows `%0 x=1 w=39` and `%1 x=41`.
- **Off.** Run `bin/tmuxlab cmd set -g pane-border-frame off`, `sleep 0.3`,
  `map`. Upstream look: `%0 x=0`, no frame at the window edges.
- **Status line.** Run `bin/tmuxlab cmd set -g pane-border-frame all`,
  `bin/tmuxlab cmd set -g pane-border-status top`, `sleep 0.3`, `map`. Each
  pane's top frame row carries its status text and its own corners; `geom`
  shows every pane still with its own `y`.
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
