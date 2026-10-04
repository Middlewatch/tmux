# Mouse resize

With `mouse on`, dragging the border between two panes resizes them
(default binding `MouseDrag1Border` to `resize-pane -M`). With
`pane-border-frame outer` the dividers between panes are shared as
upstream, so the single divider column or row is the drag handle; the
outer frame along the window edge has no divider behind it and does not
resize anything.

## Sub-features

- `resize-hit` classifies the shared divider cell as a border and the cells
  either side as inside their panes.
- `resize-columns` resizes from the divider column.
- `resize-rows` resizes from the divider row.
- `resize-amount` moves the divider by the number of cells dragged.
- `resize-floating` keeps floating panes draggable by their own borders.

## How to get to it (user POV)

- Press and drag with the left button on the line between two panes.
- `resize-pane -M` bound to a mouse key does the same.

## Driving it with tmuxlab

Preconditions:

- Lab up with `-v` and the user's config at 80x24, two splits as in
  [pane-frames](./pane-frames.md): `%0` left, `%1` top right, `%2` bottom
  right; `%0 right=39`, `%1 bottom=10`, `%2 y=12`.

- **Hit test, columns.** Run `bin/tmuxlab where 39 5`, `where 40 5`,
  `where 41 5`. They print `on pane %0`, `on pane %0 border`, `on pane %1`.
- **Hit test, rows.** Run `bin/tmuxlab where 60 10`, `where 60 11`,
  `where 60 12`. They print `on pane %1`, `on pane %1 border`, `on pane %2`.
- **Hit test, outer frame.** `where 0 5` and `where 40 0` print
  `on empty area`; `where 79 5` prints `on pane %1 border` and
  `where 40 22` prints `on pane %0 border` (a pane's own right and bottom
  edge count as its border, as upstream). None of these cells resizes.
- **Drag the column divider.** Run `bin/tmuxlab drag 40 5 30 5 5` then
  `bin/tmuxlab geom`. `%0 w=29 right=29`, `%1 x=31`, `%2 x=31`. Run
  `bin/tmuxlab drag 30 5 40 5 5`; `geom` is back to `%0 right=39`, `%1 x=41`.
- **Drag the row divider.** Run `bin/tmuxlab drag 60 11 60 15 4` then
  `geom`. `%1 h=14 bottom=14`, `%2 y=16 h=6`. Run
  `bin/tmuxlab drag 60 15 60 11 4`; `geom` is back to `%1 bottom=10`,
  `%2 y=12`.
- **Floating.** Run `cd regress && TEST_TMUX=$PWD/../tmux sh floating-pane-top-border-drag.sh`;
  exit 0 proves floating borders still drag.
- **Proof.** Run `bin/tmuxlab proof mouse-resize` after the last drag and
  cite the path together with the `geom` lines before and after.

## Gotchas

- `where` needs `up -v`; without the log it prints nothing.
- A drag only resizes when the pointer crosses a cell boundary; the
  harness sends one update per interpolated cell, so a 5-step drag over 10
  columns moves the divider 10 columns.
- The press on `MouseDown1Border` also runs `select-pane -t=`, so the active
  pane changes to the pane that owns the divider: the pane on the left of a
  column divider, the pane above a row divider.
- Upstream looks for the layout divider within one cell of the press, so
  only the divider cell itself starts a resize.
