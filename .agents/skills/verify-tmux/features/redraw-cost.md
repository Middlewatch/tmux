# Redraw cost

Every mouse-resize step makes tmux redraw the whole window (upstream
behaviour: `resize-pane -M` calls `server_redraw_window`). How many bytes
that costs decides how smooth a drag feels over a slow link. Frames add
border glyphs and colour changes to every row and move the pane edges away
from the terminal edges, so blank lines need `ECH` instead of `EL`.

## Sub-features

- `cost-per-step` measures bytes written per one-cell resize step.
- `cost-frames` compares `pane-border-frame all` with `off`.
- `cost-terminal` shows the dependence on the terminal's `ech` capability.

## How to get to it (user POV)

- Drag a divider slowly and watch for lag or tearing.

## Driving it with tmuxlab

Preconditions:

- Lab up at the user's real client size (`tmux list-clients -F
  '#{client_width}x#{client_height}'`, 280x55 at the time of writing):
  `TMUXLAB=perf bin/tmuxlab up -f ~/.config/tmux/tmux.conf -x 280 -y 55`.
- One split: `bin/tmuxlab cmd split-window -h`, `sleep 0.3`.
- `X` is `#{pane_right}` of `%0` plus 1 (the left pane's right frame).

- **Measure with frames.** Run `bin/tmuxlab bytes start`, `sleep 0.3`,
  `bin/tmuxlab bytes read` (discard), `bin/tmuxlab drag X 20 X-10 20 10`,
  `sleep 0.5`, `bin/tmuxlab bytes read`. Divide by 10. Measured on
  2026-10-03 with the user's config: about 8.0 KB per step.
- **Measure without.** Run `bin/tmuxlab cmd set -g pane-border-frame off`,
  `sleep 0.3`, drag back the other way, `bytes read`, and repeat the
  measurement. About 2.3 KB per step on the same date.
- **Terminal dependence.** Rerun the frames case with
  `TMUXLAB_TERM=tmux-256color` on `up`. Without `ech` the blank pane lines
  are written as spaces: about 23 KB per step at 280x55.
- **Composition.** After `bytes start` and a single `mouse drag`, copy the
  raw log `/tmp/tmuxlab-$(id -u)/perf/bytes.log` (the lab's state
  directory, printed by `up`) and count `━`/`┃` glyphs and `\e[...m`
  sequences to see what dominates; in the frames case colour changes are
  about half and horizontal frame glyphs a quarter.
- **Proof.** Quote the byte counts per step with the client size, config
  and `TMUXLAB_TERM`, and save `bin/tmuxlab proof redraw-cost` for the
  layout they were measured on.

## Gotchas

- `bytes read` resets the counter; always discard the first read after
  `start`, which includes the pipe-pane setup redraw.
- The count includes the status line redraw on every step; it is part of
  the real cost but not of the frames.
- Byte counts are only comparable at the same client size, config and
  `TMUXLAB_TERM`.
- Both servers run the binary under test; a crash in the outer loses the
  byte log with the lab.
