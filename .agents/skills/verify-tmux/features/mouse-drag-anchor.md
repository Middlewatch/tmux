# Mouse drag anchoring

A button-1 drag that starts on a pane or on a pane border stays with that
pane and location until the button is released. The pointer may cross a
divider, the neighbouring pane or the status line meanwhile; the drag
updates and the `MouseDragEnd1*` key still go to the pane the press landed
on, with the location of the press. Upstream re-derives both from the
pointer on every event, so a copy-on-select drag released over another
pane never ends and a drag forwarded to a mouse-aware program (vis with
`vis-mouse`, for example) turns into a border resize when it reaches the
pane's own edge. The pin is `c->tty.mouse_drag_loc`, set beside
`mouse_drag_x/y` when the drag begins (`server-client.c`,
`server_client_check_mouse`).

## Sub-features

- `dragend-follows-start` delivers `MouseDragEnd1Pane` to the pane where the
  drag began, in that pane's key table (`copy-mode-vi` when it is in copy
  mode), wherever the button is released.
- `drag-keeps-location` keeps a drag started inside a pane as
  `MouseDrag1Pane` when the pointer reaches a divider or the outer frame,
  so a mouse-aware program keeps receiving it and `resize-pane -M` never
  starts.
- `border-drag-unchanged` leaves a drag that began on a divider as a
  resize (`MouseDrag1Border` then `Dragging`), as before.

## How to get to it (user POV)

- Select text with the mouse and let go after the pointer has strayed into
  the next pane: the selection is copied and copy mode ends.
- Inside a program with the mouse on, drag a selection up to the edge of
  the pane: the program keeps the drag and the divider stays put.
- Click a pane to focus it with a small slip of the hand onto the divider:
  copy mode still ends on release.

## Driving it with tmuxlab

Preconditions:

- Lab up with `-v`, the user's config and shells: `bin/tmuxlab up -v -f
  ~/.config/tmux/tmux.conf -x 80 -y 24 -c sh`, then `cmd split-window -h`
  and `cmd kill-pane` on any extra pane the config spawned until two
  remain. `geom` gives `LEFT` (x=1) and `RIGHT`; the examples below use
  `%0 x=1..39` and `%9 x=41..78`, row 2 holding a line echoed in each pane
  (`cmd send-keys -t %0 'echo abcdefghijklmnopqrstuvwxyz0123456789' Enter`).
  Adjust columns to what `geom` prints.
- Buffers cleared (`cmd delete-buffer` until it errors) before each check.

- **Release over the other pane.** `mouse press 3 2`, `mouse drag 7 2`,
  `mouse drag 13 2`, `mouse drag 46 2`, `mouse release 46 2`. Then
  `cmd display -p -t %0 '#{pane_in_mode}'` prints `0` and `cmd show-buffer`
  prints the selected run of letters. `log` shows `mouse key is
  MouseDragEnd1Pane` followed by `key table copy-mode-vi (pane %0)`. Before
  the fix the table line read `root (pane %9)`, `pane_in_mode` stayed `1`
  and there was no buffer.
- **Mouse-aware pane dragged to its edge.** Turn the mouse on in `%0` with
  `cmd send-keys -t %0 "printf '\033[?1002h'" Enter` and confirm `cmd
  display -p -t %0 '#{mouse_any_flag}'` prints `1`. Note `geom` for `%0`,
  then `mouse press 6 2`, `mouse drag 11 2`, `mouse drag 39 2`, `mouse drag
  40 2`, `mouse drag 43 2`, `mouse release 43 2`. `geom` is unchanged and
  `log` shows only `MouseDrag1Pane` resolutions and a `MouseDragEnd1Pane`,
  no `MouseDrag1Border`. Before the fix the event at column 40 resolved to
  `MouseDrag1Border` and `%0` grew by the dragged distance.
- **Divider drag still resizes.** `bin/tmuxlab drag 40 5 30 5 5` then
  `geom`: `%0 right=29`, as in [mouse-resize](./mouse-resize.md).
- **Regress.** `cd regress && TEST_TMUX=$PWD/../tmux sh
  mouse-drag-stays-on-pane.sh`; exit 0 covers the first two checks with
  upstream's default bindings.
- **Proof.** `bin/tmuxlab proof mouse-drag-anchor` after the second check
  and cite the path with the `geom` lines before and after.

## Gotchas

- The pin applies only to drags that began on a pane or border. Drags from
  the status line, a scrollbar, empty space or a control range keep
  upstream's per-event resolution.
- A pin needs `mouse_last_pane`; a pane killed mid-drag clears it and the
  rest of the drag falls back to upstream behaviour.
- A long shell prompt wraps the echoed line: check `screen` for which row
  holds the letters before choosing coordinates.
- Clicks are not drags: a focus click with one cell of motion still starts
  copy mode and, with the user's `MouseDragEnd1Pane` binding, copies that
  cell; two clicks within 300 ms copy the word under the pointer through
  upstream's default `DoubleClick1Pane`. Both are bindings, not hit tests.
- `send-keys "printf '\033[?1002h'"` takes a moment to reach the shell;
  read `mouse_any_flag` after a short sleep or the check sees the old value.
