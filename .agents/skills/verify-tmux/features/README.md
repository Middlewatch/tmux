# tmux fork verification map

This directory is the maintained source for verifying the user-facing
behaviour of the fork's local patches. Read the index before driving the
binary, then use the matching feature file as the recipe. The recipes use
`bin/tmuxlab` from the parent skill; its commands are described in
`../SKILL.md`.

## Baseline preconditions

- `make` has produced `~/projects/tmux/tmux` from the current tree.
- A lab is up with the user's config and debug logging:
  `bin/tmuxlab up -v -f ~/.config/tmux/tmux.conf -x 80 -y 24`.
- The user's config puts the status line on top, so window row N is map
  row N+1. `bin/tmuxlab geom` prints the offset.
- `bin/tmuxlab doctor` reports `frame: all, lines: heavy` and exits 0.
- Only drive labs this run started; never point the harness at the
  user's default socket.

## Driving conventions

- Coordinates in recipes are window cells, 0-based, as `list-panes`
  reports them; `mouse`, `drag` and `where` take those directly.
- Start every recipe from a fresh lab unless its preconditions say
  otherwise; `bin/tmuxlab down` then `up` is cheap.
- Give layout changes ~0.3 s before capturing.
- Keep quoted commands literal; the inner tmux parses them as typed.

## Proof and skip reporting

- Capture the state before the action and after it, not only the end.
- Pair every visual claim (`map`, `screen`) with the geometry or hit
  classification behind it (`geom`, `where`, `display -p`).
- Save the final state with `bin/tmuxlab proof <feature-id>` and cite the
  printed path.
- Report an unreachable path with the command tried and the unmet
  precondition. A skipped entry point is not verified by another one.

## Feature entry contract

Each feature file starts with an H1 title and one paragraph describing the
user-visible behaviour, then exactly four H2 sections in this order:
`Sub-features`, `How to get to it (user POV)`, `Driving it with tmuxlab`
(starting with `Preconditions:`, then labelled bullets pairing a user
action with an exact command and the observable result), and `Gotchas`.

## Features

- [Pane frames](./pane-frames.md): `pane-border-frame off|outer|all`
  rendering, the gap column, stacked frames, and how the gap is styled.
- [Mouse resize](./mouse-resize.md): which cells between two panes start a
  drag-resize, in both axes, and the hit classification behind them.
- [Pane selection and navigation](./pane-navigation.md): mouse click
  selection on panes and frames, and `select-pane -UDLR` across frames.
- [Redraw cost](./redraw-cost.md): bytes written per mouse-resize step with
  and without frames, for judging drag smoothness.
