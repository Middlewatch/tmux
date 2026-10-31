#!/bin/sh

# With pane-border-frame outer, a pane on a window edge gives one column or
# row to the frame. split-window -l, join-pane -l and resize-pane -x/-y name
# the size of the pane, so a pane that sits on the framed edge needs a cell
# one bigger. Before the fix every such request came out one short.

PATH=/bin:/usr/bin
TERM=screen

[ -z "$TEST_TMUX" ] && TEST_TMUX=$(readlink -f ../tmux)
TMUX="$TEST_TMUX -Ltest$$ -f/dev/null"
trap '$TMUX kill-server 2>/dev/null' 0
trap 'exit 1' 1 2 15

fail=0
check() {
	# $1 label, $2 want, $3 got
	if [ "$2" = "$3" ]; then
		echo "ok   $1: $3"
	else
		echo "FAIL $1: want $2 got $3"
		fail=1
	fi
}
width() { $TMUX display -p -t "$1" '#{pane_width}'; }
height() { $TMUX display -p -t "$1" '#{pane_height}'; }

$TMUX new-session -d -s t -x 200 -y 50 || exit 1
$TMUX set -g pane-border-frame outer

# Right edge: a split to the right.
R=$($TMUX split-window -h -l 30 -P -F '#{pane_id}' -t t:0.0)
check "split -h -l 30 on the right edge" 30 "$(width "$R")"

# Left edge: a split placed before the leftmost pane.
L=$($TMUX split-window -hb -l 20 -P -F '#{pane_id}' -t t:0.0)
check "split -hb -l 20 on the left edge" 20 "$(width "$L")"

# Absolute resizes on framed edges.
$TMUX resize-pane -x 40 -t "$R"
check "resize -x 40 on the right edge" 40 "$(width "$R")"
$TMUX resize-pane -x 25 -t "$L"
check "resize -x 25 on the left edge" 25 "$(width "$L")"

# The middle pane touches no vertical frame: unchanged behaviour.
M=$($TMUX display -p -t t:0.1 '#{pane_id}')
$TMUX resize-pane -x 60 -t "$M"
check "resize -x 60 in the middle" 60 "$(width "$M")"

# Bottom edge: a split below, then a resize.
B=$($TMUX split-window -v -l 10 -P -F '#{pane_id}' -t "$R")
check "split -v -l 10 on the bottom edge" 10 "$(height "$B")"
$TMUX resize-pane -y 15 -t "$B"
check "resize -y 15 on the bottom edge" 15 "$(height "$B")"

# Top edge: a split placed above the top pane.
T=$($TMUX split-window -vb -l 8 -P -F '#{pane_id}' -t "$R")
check "split -vb -l 8 on the top edge" 8 "$(height "$T")"

# join-pane -hb -l at the left edge (the sidebar unpark path).
$TMUX break-pane -d -s "$L" -t t:
$TMUX join-pane -hb -l 24 -s "$L" -t "$M"
check "join -hb -l 24 on the left edge" 24 "$(width "$L")"

# A window with the frame off is untouched.
$TMUX set -g pane-border-frame off
$TMUX new-window -t t
R2=$($TMUX split-window -h -l 30 -P -F '#{pane_id}' -t t:1)
check "frame off: split -h -l 30" 30 "$(width "$R2")"
$TMUX resize-pane -x 40 -t "$R2"
check "frame off: resize -x 40" 40 "$(width "$R2")"

exit $fail
