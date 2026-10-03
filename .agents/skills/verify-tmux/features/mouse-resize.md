# Mouse resize

With `mouse on`, dragging the border between two panes resizes them
(default binding `MouseDrag1Border` to `resize-pane -M`). With
`pane-border-frame all` the cells between two side-by-side panes are the
left pane's right frame, the gap column and the right pane's left frame;
between stacked panes they are the upper pane's bottom frame and the lower
pane's top frame. Every one of those cells must start a resize drag.

## Sub-features

- `resize-hit` classifies every frame and gap cell as a border.
- `resize-columns` resizes from the left frame, the gap and the right frame.
- `resize-rows` resizes from the bottom frame and the top frame.
- `resize-amount` moves the divider by the number of cells dragged.
- `resize-floating` keeps floating panes draggable by their own borders.

## How to get to it (user POV)

- Press and drag with the left button anywhere between two panes.
- `resize-pane -M` bound to a mouse key does the same.

## Driving it with tmuxlab

Preconditions:

- Lab up with `-v` and the user's config at 80x24, two splits as in
  [pane-frames](./pane-frames.md): `%0` left, `%1` top right, `%2` bottom
  right; `%0 right=38`, `%1 bottom=9`, `%2 y=12`.

- **Hit test, columns.** Run `bin/tmuxlab where 39 5`, `where 40 5`,
  `where 41 5`. All three print `on pane %N border` (39 for `%0`, 40 and 41
  for `%1`); `where 38 5` prints `on pane %0` and `where 42 5` prints
  `on pane %1`.
- **Hit test, rows.** Run `bin/tmuxlab where 60 10` and `where 60 11`. Both
  print a border (`%1` then `%2`); `where 60 9` and `where 60 12` are inside
  the panes.
- **Drag from the gap.** Run `bin/tmuxlab drag 40 5 30 5 5` then
  `bin/tmuxlab geom`. `%0 w=28 right=28`, `%1 x=32`, `%2 x=32`.
- **Drag from the right pane's left frame.** Run `bin/tmuxlab drag 31 5 45 5 5`
  then `geom`. `%0 w=42 right=42`, `%1 x=46`.
- **Drag from the left pane's right frame.** Run `bin/tmuxlab drag 44 5 40 5 4`
  then `geom`. `%0 w=38 right=38`, `%1 x=42` (back to the start).
- **Drag from the bottom frame.** Run `bin/tmuxlab drag 60 10 60 14 4` then
  `geom`. `%1 h=13 bottom=13`, `%2 y=16`.
- **Drag from the top frame.** Run `bin/tmuxlab drag 60 15 60 9 6` then
  `geom`. `%1 h=7 bottom=7`, `%2 y=10`.
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
  pane changes to the pane that owns the cell: left frame and gap belong to
  the pane on the right, the right frame to the pane on the left.
- Upstream looks for the layout divider within one cell of the press, so a
  frame two cells from the divider would not resize; with `all` every
  border cell is within one cell of the divider in both axes.
