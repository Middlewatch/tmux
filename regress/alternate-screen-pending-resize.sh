#!/bin/sh

# A pane that enters the alternate screen while a resize is still queued
# behind its resize timer must still get that resize: afterwards the pty
# size has to match the pane size. Programs that switch to the alternate
# screen at startup (fish probes it, nnn and vis live in it) lost the
# second of two quick splits and drew for the old size until the next
# resize.

PATH=/bin:/usr/bin
TERM=screen

[ -z "$TEST_TMUX" ] && TEST_TMUX=$(readlink -f ../tmux)
TMUX="$TEST_TMUX -Ltest$$ -f/dev/null"
trap '$TMUX kill-server 2>/dev/null; rm -f "$TMP"' 0
trap 'exit 1' 1 2 15
TMP=$(mktemp)

$TMUX new-session -d -x 80 -y 48

# The first split sizes the new pane and arms its 250 ms resize timer; the
# second split queues behind the timer; the pane's program then enters the
# alternate screen while that resize is still pending, and reports the
# size its tty ends up with.
P=$($TMUX split-window -v -P -F '#{pane_id}' -- sh -c \
	"sleep 0.1; printf '\\033[?1049h'; sleep 1; stty size >$TMP; sleep 5")
$TMUX split-window -v -d -t "$P"
sleep 2

want=$($TMUX display -p -t "$P" '#{pane_height} #{pane_width}')
got=$(cat "$TMP")
if [ "$got" != "$want" ]; then
	echo "pty size: expected '$want' but got '$got'"
	exit 1
fi

exit 0
