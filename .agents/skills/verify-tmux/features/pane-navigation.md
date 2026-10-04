# Pane selection and navigation

Clicking a pane makes it active; clicking a shared divider selects the
pane that owns it (the pane above a row divider, the pane left of a column
divider). `select-pane -U/-D/-L/-R` moves between neighbours using layout
geometry, so the frame insets must not break adjacency, and
`select-pane -t top-left` and friends must land inside a pane.

## Sub-features

- `select-click` activates the clicked pane.
- `select-click-border` activates the owner of a divider cell.
- `navigate-arrows` moves to the right neighbour across a column divider
  and to the lower neighbour across a row divider.
- `navigate-targets` resolves `top-left`, `bottom-right` and the like.

## How to get to it (user POV)

- Left-click inside a pane or on a divider.
- `prefix` with the arrow keys, or `select-pane -L/-R/-U/-D`.
- `select-pane -t top-left` from the prompt.

## Driving it with tmuxlab

Preconditions:

- Lab up with the user's config at 80x24 and the three-pane layout from
  [pane-frames](./pane-frames.md). `%2` is active after the splits.

- **Click inside.** Run `bin/tmuxlab mouse click 10 10` then
  `bin/tmuxlab cmd display -p '#{pane_id}'`. Prints `%0`.
- **Click a row divider.** Run `bin/tmuxlab mouse click 42 11` (the divider
  between `%1` and `%2`) then `display -p '#{pane_id}'`. Prints `%1`, the
  pane above.
- **Click a column divider.** Run `bin/tmuxlab mouse click 40 5` then
  `display -p '#{pane_id}'`. Prints `%0`, the pane on the left.
- **Click the outer frame.** `mouse click 79 5` prints `%1` and
  `mouse click 40 22` prints `%0` (a pane's own right and bottom edge). With
  `%1` active, `mouse click 0 5` and `mouse click 40 0` leave `%1` active:
  the left and top frame cells belong to no pane.
- **Arrows.** Run `bin/tmuxlab cmd select-pane -t %0`, then
  `bin/tmuxlab cmd select-pane -R` and `display -p '#{pane_id}'`: `%1`.
  Then `select-pane -D`: `%2`. Then `select-pane -L`: `%0`.
- **Targets.** Run `bin/tmuxlab cmd select-pane -t bottom-right` and
  `display -p '#{pane_id}'`: `%2`. `select-pane -t top-left`: `%0`.
- **Proof.** Run `bin/tmuxlab proof pane-navigation`; the saved `geom.txt`
  shows the active pane, and the command outputs above are the evidence of
  each step.

## Gotchas

- `select-pane -D` from `%0` picks the pane below by layout cell geometry;
  with a single pane on the left there is none, so it stays on `%0`.
- Right and bottom outer frame cells count as the adjacent pane's border
  (upstream treats a pane's right and bottom edge as its own); left and top
  frame cells are empty area. Neither resizes anything.
- Clicking changes which pane later `cmd` calls without `-t` act on; pass
  `-t` when it matters.
