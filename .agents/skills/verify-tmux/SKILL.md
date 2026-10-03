---
name: verify-tmux
description: "Drive the fork's tmux binary in an isolated lab and capture what it renders. Use to inspect pane layout and borders, calibrate mouse behaviour (hit testing, drag-resize), measure redraw cost, or prove a fix in this tree before installing it. Not for the user's live tmux server."
---

# Verify the tmux fork

`bin/tmuxlab` runs the binary under test (`~/projects/tmux/tmux`) as an
inner tmux attached inside a pane of an outer tmux, both on private
sockets. The outer pane is the inner client's terminal, so the rendered
screen can be captured as text and mouse events can be injected as SGR
escape sequences. Nothing here touches the user's own server or sockets.

Paths below are relative to this directory. `features/` is the maintained
map of user-facing behaviour; read `features/README.md` and the feature
file for the behaviour under test before driving anything.

## Launch

Build once, then start a lab:

```sh
cd ~/projects/tmux && make            # binary under test is ./tmux
bin/tmuxlab up -v -f ~/.config/tmux/tmux.conf -x 120 -y 40
```

- `-f CONF` sources the user's config (frames, heavy lines, mouse on,
  status at top). Without `-f` the inner runs bare defaults plus the lab
  settings; set `pane-border-frame` yourself in that case.
- `-v` starts the inner server with debug logging. `where` and `log`
  need it; everything else works without.
- `-x/-y` size the client. Use the user's real size (280x55 at the time
  of writing, see `tmux list-clients -F '#{client_width}x#{client_height}'`)
  when measuring redraw cost.
- Ready when `up` prints `lab '<name>' up: WxH client`. The lab config is
  written to the state directory it names.
- Panes run `bin/labpane` by default: it prints its pane id on the first
  line and then echoes typed lines, so a capture identifies each pane and
  `keys` leaves visible evidence. This is verification scaffolding; pass
  `-c sh` for a real shell.
- Several labs can run side by side: `TMUXLAB=perf bin/tmuxlab up ...`
  and the same prefix on every later call.

## Doctor

```sh
bin/tmuxlab doctor
```

Read-only. Reports the binary and its version, both servers, the inner
client's size and TERM, and the frame and line options in effect, and
exits 1 when the lab is unfit (server down, version mismatch, more than
one inner client). Run it first whenever a capture looks wrong.

## Drive

Coordinates are window cells, 0-based, the same numbers `list-panes`
reports as `pane_left`, `pane_top`, `pane_right`, `pane_bottom`. The
script adds the status line offset when the inner status is at the top.

- `bin/tmuxlab cmd <tmux command>`: any command on the inner server, e.g.
  `cmd split-window -h`, `cmd set -g pane-border-frame all`,
  `cmd select-layout tiled`, `cmd list-panes -F '#{pane_id} #{pane_left}'`.
- `bin/tmuxlab keys <send-keys args>`: keystrokes to the inner client.
- `bin/tmuxlab mouse press|release|drag|move|click|wheelup|wheeldown X Y [-b N]`:
  one SGR mouse event at cell X,Y.
- `bin/tmuxlab drag X1 Y1 X2 Y2 [STEPS]`: press, STEPS drag updates along
  the line, release. One update per cell gives the real per-cell cost.
- `bin/tmuxlab where X Y`: moves the pointer and prints the inner server's
  own classification of that cell (`on pane %N`, `on pane %N border`,
  `on empty area`). Needs `up -v`. This is the authoritative hit test.
- `bin/tmuxlab geom`: window and client size, status position with the row
  offset, frame/lines/status options, layout string, pane rectangles.

## Evidence

- `bin/tmuxlab screen [-e]`: the rendered inner client as text, with SGR
  when `-e`.
- `bin/tmuxlab map`: a cell map with a column ruler and row numbers:
  box-drawing glyphs as themselves, `#` for a blank cell drawn with a
  non-default background, `.` for other text, space for a plain blank.
  Rows are client rows; with the user's config window row N is map row
  N+1 because the status line is on top.
- `bin/tmuxlab bytes start|read|stop`: records everything the inner
  client writes to its terminal; `read` prints the byte count since the
  last read. Wrap a drag in `read` calls to measure redraw cost per step.
- `bin/tmuxlab proof NAME`: saves `screen.txt`, `screen.ansi`, `map.txt`,
  `geom.txt` and `about.txt` (binary, version, lab config) under
  `~/projects/tmux/.local/verify/<timestamp>-NAME/` and prints the path.

Proof standards:

- Drive the real user path: mouse events through the client and commands
  a user could type, never internal setters.
- Capture before and after: `geom` or `map` ahead of the action, the
  action, then `geom`/`map`/`proof` again. A final screen alone does not
  show that the action did it.
- Check the side effect, not only the picture: pane geometry from
  `list-panes`, the active pane from `display -p '#{pane_id}'`, the
  server's hit classification from `where`.
- Give redraws ~0.3 s to land before capturing (`drag` and `where`
  already wait; add `sleep 0.3` after `cmd` calls that change layout).
- Measure bytes with `TMUXLAB_TERM` left at its default (`xterm-256color`,
  which has `ech` like foot); `tmux-256color` lacks `ech` and inflates
  blank-line clears into runs of spaces.

## Cleanup

```sh
bin/tmuxlab down           # kills both servers of this lab, removes state
```

`down` only kills the two servers whose socket names carry the lab name,
and removes the lab's state directory (configs, server log, byte log).
Proof directories under `~/projects/tmux/.local/verify/` are not touched;
confirm the one you need exists after `down`. If a lab is left over from
a failed run, `down` is safe to run cold; `ls /tmp/tmux-$(id -u)/` lists
sockets if you need to see which labs exist.

## Helpers

- `bin/tmuxlab` (executable): the driver; `bin/tmuxlab help` lists
  commands and environment variables (`TMUXLAB`, `TEST_TMUX`,
  `TMUXLAB_TERM`, `TMUXLAB_DIR`, `TMUXLAB_EVIDENCE`, `TMUXLAB_DELAY`).
- `bin/labpane` (executable): default pane command described above.
- Upstream's `regress/*.sh` are the other harness; run one with
  `cd regress && TEST_TMUX=$PWD/../tmux sh <test>.sh`. They share the
  inner-inside-outer trick but each builds its own scene.
