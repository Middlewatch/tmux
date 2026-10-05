# Middlewatch tmux fork

This is the owner's fork of [tmux/tmux](https://github.com/tmux/tmux),
tracking upstream master with local patches on top. The owner has
authorized hacking, feature work, and bug fixing in this tree without a
per-change check-in, and intends to own and run this version of tmux until
stated otherwise. Upstream drift is an accepted cost: rebase when upstream
has something wanted or when a platform change forces it, not on a
schedule.

## Layout

- `upstream` remote: tmux/tmux master. `origin` is the owner's fork,
  github.com/Middlewatch/tmux, whose default branch is `outer-border` so a
  plain clone gives the patched tree. Local work lives on feature branches
  (`outer-border` carries the patches) rebased onto upstream.
- Patches stay small, follow upstream's KNF style, and land with a commit
  message that explains the behaviour and names known rough edges, so a
  future rebase can judge each one on its own.
- `bin/install [PREFIX]` runs `autogen.sh`, `configure --prefix`, `make`
  and `make install`, default prefix `~/.local`, so the installed binary is
  `~/.local/bin/tmux`, shadowing Fedora's `/usr/bin/tmux`, which stays as
  the fallback. Its header lists the build dependencies. A new server is
  needed after installing; clients and servers of different versions do
  not talk.

## Build and test

- `sh autogen.sh && ./configure && make` needs autoconf, automake,
  libevent-devel, and ncurses-devel. Without root they can be extracted
  from Fedora rpms into a scratch prefix; the inbox note
  `rootless-autotools-build-from-extracted-fedora-rpms` has the recipe.
- `regress/*.sh` are upstream's tests, run from `regress/` with
  `TEST_TMUX=$PWD/../tmux sh <test>.sh`. The redraw ones render scenes by
  attaching an inner tmux inside an outer one and capturing the pane; the
  same trick is the quickest way to eyeball a border or layout change
  without a terminal.
- Expected regress results: every test passes except
  `copy-mode-selection-mode.sh`, `copy-mode-selection-scroll.sh` and
  `format-mouse.sh`, which fail on upstream `596d04a1` as well. A failure
  outside that set is a regression. The tests for removed features
  (`clock-mode`, `customize-mode`, `server-access`, `wait-for`) went with
  the features; the tests that used them as scaffolding were rewritten on
  `choose-tree`, `choose-client` and `choose-buffer`, except the
  customize-mode option-mutation case, which has no replacement.
- Generated files (`configure`, `Makefile.in`, logs) are gitignored; keep
  build logs out of the tree. `.local/` is the unversioned surround;
  verification evidence lands in `.local/verify/`.
- `.agents/skills/verify-tmux/` is the lab for eyeballing and proving
  behaviour without a terminal: `bin/tmuxlab up -v -f
  ~/.config/tmux/tmux.conf` starts the fork binary inside a capturing
  tmux, then `cmd`, `mouse`, `drag`, `where`, `map`, `geom`, `bytes` and
  `proof` drive and record it. Read its `SKILL.md` and `features/`
  before working on layout, borders or mouse behaviour.

## Local patches

- `pane-border-frame off|outer`: `outer` adds a border along the window
  edge so every pane is framed on all four sides; dividers between panes
  stay shared as upstream (`outer-border` branch). An `all` mode that gave
  each pane its own frame with a gap column was built and removed: the
  owner preferred the tighter shared dividers. Known rough edges are listed
  in the commit messages.
- Access control is the socket directory. `/tmp/tmux-<uid>` is created
  `0700` and every accepted connection becomes a full client; upstream's
  `server-access` list, which denied other uids by default, is gone
  (`f399b624`). This is a single-user build: never loosen that directory
  (an existing one with `g+rwx` is accepted) and never hand a `-S` socket
  path to another account.
