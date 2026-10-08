#!/bin/sh

# A mouse drag that starts on a pane stays with that pane until the button is
# released. Releasing a copy mode selection over the neighbouring pane must
# still deliver MouseDragEnd1Pane to the pane in copy mode, and a drag
# forwarded to a program with the mouse on must not turn into a border resize
# when the pointer reaches the pane's own edge.

PATH=/bin:/usr/bin
TERM=screen
LC_ALL=C.UTF-8
export PATH TERM LC_ALL

[ -z "$TEST_TMUX" ] && TEST_TMUX=$(readlink -f ../tmux)

TMUX="$TEST_TMUX -Ldragpane-inner-$$ -f/dev/null"
TMUX2="$TEST_TMUX -Ldragpane-outer-$$ -f/dev/null"

fail()
{
	echo "$*" >&2
	exit 1
}

cleanup()
{
	$TMUX2 kill-server 2>/dev/null
	$TMUX kill-server 2>/dev/null
}
trap cleanup 0 1 15

# One SGR mouse event sent to the outer pane holding the inner client: $1 is
# the button code (0 press/release, 32 drag), $2 and $3 the 1-based column
# and row, $4 M for press or drag and m for release.
mouse()
{
	seq=$(printf '\033[<%s;%s;%s%s' "$1" "$2" "$3" "$4")
	$TMUX2 send-keys -t "$OUTER" -l "$seq" 2>/dev/null
	sleep 0.2
}

# Two panes side by side; cat echoes typed text so the left pane has a line
# to select.
$TMUX new-session -d -s inner -x 80 -y 20 'cat' || exit 1
$TMUX set -g status off || exit 1
$TMUX set -g window-size manual || exit 1
$TMUX set -g mouse on || exit 1
$TMUX split-window -h 'cat' || exit 1
LEFT=$($TMUX list-panes -F '#{pane_id}' | head -1)
RIGHT=$($TMUX list-panes -F '#{pane_id}' | tail -1)
$TMUX send-keys -t "$LEFT" -l 'abcdefghijklmnopqrstuvwxyz' || exit 1
LRIGHT=$($TMUX display-message -p -t "$LEFT" '#{pane_right}')
RLEFT=$($TMUX display-message -p -t "$RIGHT" '#{pane_left}')

$TMUX2 new-session -d -s outer -x 80 -y 20 "$TMUX attach -t inner" || exit 1
sleep 1
OUTER=$($TMUX2 list-panes -F '#{pane_id}' | head -1)
[ -n "$OUTER" ] || fail "no outer pane"

# Select from c to j in the left pane, carry on into the right pane and
# release there. The default MouseDragEnd1Pane binding copies and cancels.
mouse 0 3 1 M
mouse 32 10 1 M
mouse 32 $((RLEFT + 6)) 1 M
mouse 0 $((RLEFT + 6)) 1 m
sleep 0.3
[ "$($TMUX display-message -p -t "$LEFT" '#{pane_in_mode}')" = 0 ] ||
    fail "left pane still in copy mode after release over the right pane"
[ "$($TMUX show-buffer 2>&1)" = "cdefghij" ] ||
    fail "selection not copied on release over the right pane"

# Now the left pane runs a program with the mouse on, so drags are forwarded
# to it rather than starting copy mode. Drag from inside the pane across its
# right edge: the divider must not move.
$TMUX respawn-pane -k -t "$LEFT" 'printf "\033[?1002h"; cat' || exit 1
sleep 0.3
[ "$($TMUX display-message -p -t "$LEFT" '#{mouse_any_flag}')" = 1 ] ||
    fail "left pane did not turn the mouse on"
mouse 0 6 1 M
mouse 32 $((LRIGHT + 1)) 1 M
mouse 32 $((LRIGHT + 2)) 1 M
mouse 32 $((LRIGHT + 6)) 1 M
mouse 0 $((LRIGHT + 6)) 1 m
sleep 0.3
[ "$($TMUX display-message -p -t "$LEFT" '#{pane_right}')" = "$LRIGHT" ] ||
    fail "drag inside a mouse pane resized it on reaching its border"

exit 0
