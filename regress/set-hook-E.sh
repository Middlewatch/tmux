#!/bin/sh

# set-hook -E fires a user event and -R runs a hook immediately. The event
# waiters (wait-for -E) that upstream's version of this test also covered are
# not part of this tree.

PATH=/bin:/usr/bin
TERM=screen
LC_ALL=C.UTF-8
LANG=C.UTF-8
export TERM LC_ALL LANG

[ -z "$TEST_TMUX" ] && TEST_TMUX=$(readlink -f ../tmux)
OUT=$(mktemp -d)
TMUX_TMPDIR="$OUT"
export TMUX_TMPDIR
TMUX="$TEST_TMUX -LtestA$$ -f/dev/null"

fail()
{
	echo "$*" >&2
	$TMUX kill-server 2>/dev/null || true
	rm -rf "$OUT"
	exit 1
}

cleanup()
{
	$TMUX kill-server 2>/dev/null || true
	rm -rf "$OUT"
}
trap cleanup EXIT

wait_for()
{
	option=$1
	expected=$2
	i=0

	while [ $i -lt 30 ]; do
		value=$($TMUX show -gqv "$option" 2>/dev/null || true)
		[ "$value" = "$expected" ] && return 0
		i=$((i + 1))
		sleep 0.2
	done
	fail "expected $option to be '$expected' but got '$value'"
}

$TMUX new -d -s one || fail "new-session one failed"
$TMUX new -d -s two || fail "new-session two failed"

$TMUX set-hook -E @no-sink || fail "set-hook -E @no-sink failed"

pane=$($TMUX display -pt two:0.0 '#{pane_id}') ||
	fail "display-message pane failed"
$TMUX set -g @hook_seen 0 || fail "set @hook_seen failed"
$TMUX set-hook -g @manual-hook \
	'set -gF @hook_seen "#{hook}:#{session_name}:#{window_index}:#{pane_id}"' ||
	fail "set-hook @manual-hook failed"

$TMUX set-hook -E -t two:0.0 @manual-hook ||
	fail "set-hook -E @manual-hook failed"
wait_for @hook_seen "@manual-hook:two:0:$pane"

$TMUX set -g @r_hook 0 || fail "set @r_hook failed"
$TMUX set-hook -g @manual-r 'set -g @r_hook 1' ||
	fail "set-hook @manual-r failed"
$TMUX set-hook -R @manual-r || fail "set-hook -R @manual-r failed"
wait_for @r_hook 1

if $TMUX set-hook -E window-renamed 2>/dev/null; then
	fail "set-hook -E window-renamed succeeded"
fi

exit 0
