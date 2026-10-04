#!/bin/sh

# A mode entered with -k kills its pane when it exits. The commands that make
# a mode exit as a side effect must stop using the pane afterwards; each case
# here used to take the server down.

PATH=/bin:/usr/bin
TERM=screen

[ -z "$TEST_TMUX" ] && TEST_TMUX=$(readlink -f ../tmux)
TMP=$(mktemp -d) || exit 1
TMUX_TMPDIR="$TMP"
export TMUX_TMPDIR
TMUX="$TEST_TMUX -LtestA$$ -f/dev/null"

cleanup()
{
	$TMUX kill-server 2>/dev/null
	rm -rf "$TMP"
}
trap cleanup EXIT

fail()
{
	echo "$1" >&2
	cleanup
	exit 1
}

# $1 label, $2 command entering the mode with -k, $3... command making it exit.
check()
{
	label=$1
	enter=$2
	shift 2

	$TMUX kill-server 2>/dev/null
	sleep 0.2
	$TMUX new -d -s "$label" -x 80 -y 24 'cat' ||
		fail "$label: new-session failed"
	$TMUX split-window -h -t "$label:0" 'cat' ||
		fail "$label: split-window failed"
	victim=$($TMUX display -p -t "$label:0.1" '#{pane_id}') ||
		fail "$label: display-message failed"
	$TMUX $enter -t "$victim" || fail "$label: $enter failed"
	$TMUX "$@" -t "$victim" 2>/dev/null
	sleep 0.2
	$TMUX display -p 'alive' >/dev/null 2>&1 ||
		fail "$label: server exited"
	panes=$($TMUX list-panes -t "$label:0" -F x | grep -c x)
	[ "$panes" = 1 ] || fail "$label: expected 1 pane, have $panes"
}

check panes-copy 'display-panes -k -d 0' copy-mode
check copy-clear 'copy-mode -k' clear-history
check copy-respawn 'copy-mode -k' respawn-pane -k

exit 0
