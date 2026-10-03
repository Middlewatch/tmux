# Middlewatch tmux fork

This is the owner's fork of [tmux/tmux](https://github.com/tmux/tmux),
tracking upstream master with local patches on top. The owner has
authorized hacking, feature work, and bug fixing in this tree without a
per-change check-in, and intends to own and run this version of tmux until
stated otherwise. Upstream drift is an accepted cost: rebase when upstream
has something wanted or when a platform change forces it, not on a
schedule.

## Layout

- `upstream` remote: tmux/tmux master. Local work lives on feature
  branches (`outer-border` carries the first patch) rebased onto it.
- Patches stay small, follow upstream's KNF style, and land with a commit
  message that explains the behaviour and names known rough edges, so a
  future rebase can judge each one on its own.
- The installed binary is `~/.local/bin/tmux` (`make install
  prefix=$HOME/.local`), shadowing Fedora's `/usr/bin/tmux`, which stays as
  the fallback. A new server is needed after installing; clients and
  servers of different versions do not talk.

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

- `pane-border-frame off|outer|all`: `outer` adds borders along the window
  edge so every pane is framed; `all` gives each pane its own frame so the
  active frame highlights on all sides (`outer-border` branch). Side by
  side, frames are separated by one gap column drawn as a blank in
  `pane-border-style`; stacked frames sit on adjacent rows with no gap, so
  the spacing looks the same both ways on a 2:1 cell font. Every cell
  between two panes (frame, gap, frame) is a mouse drag handle. Known
  rough edges are listed in the commit messages.
