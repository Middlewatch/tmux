#!/bin/sh

# Tests of the OSC 7501 program status sequence: reports, the feature
# detection reply, the pane_ps_* and window_ps_state formats, the
# pane-program-status hook, and what survives process exit.

PATH=/bin:/usr/bin
TERM=screen

[ -z "$TEST_TMUX" ] && TEST_TMUX=$(readlink -f ../tmux)
TMUX="$TEST_TMUX -Ltest$$ -f/dev/null"
trap '$TMUX kill-server 2>/dev/null; rm -f "$TMP" "$TMP.py"' 0
trap 'exit 1' 1 2 15
TMP=$(mktemp)

$TMUX new-session -d -x 80 -y 24 -s main
$TMUX set -g remain-on-exit on
$TMUX set -g default-shell /bin/sh
P=$($TMUX display -p '#{pane_id}')

# check $name $expected $format
check()
{
	out=$($TMUX display -p -t "$P" "$3")
	if [ "$out" != "$2" ]; then
		echo "$1: expected '$2' but got '$out'"
		exit 1
	fi
}

# report $body: have the pane's shell write OSC 7501 ; body ST
report()
{
	$TMUX send-keys -t "$P" "printf '\\033]7501;$1\\033\\\\'" Enter
	sleep 0.2
}

# "Hello, world" and unpadded "pi 2" in base64
report 'state=working:app=pi:msg=SGVsbG8sIHdvcmxk'
check state working '#{pane_ps_state}'
check app pi '#{pane_ps_app}'
check msg 'Hello, world' '#{pane_ps_msg}'
check window working '#{window_ps_state}'
check kind-only-when-blocked '' '#{pane_ps_kind}'

report 'state=blocked:kind=permission:progress=40:msg=cGkgMg'
check blocked blocked '#{pane_ps_state}'
check kind permission '#{pane_ps_kind}'
check progress 40 '#{pane_ps_progress}'
check unpadded 'pi 2' '#{pane_ps_msg}'
check record-replaced '' '#{pane_ps_app}'

# a report is dropped whole when the state is unknown, the message decodes
# to a control character ("a\nb") or it names a child record
report 'state=bogus:app=x'
check unknown-state blocked '#{pane_ps_state}'
report 'state=done:msg=YQpi'
check control-character blocked '#{pane_ps_state}'
report 'state=done:id=child'
check child-record blocked '#{pane_ps_state}'

# unknown keys are skipped and whitespace around keys and values is trimmed
report ' state = done : zzz=1 '
check done done '#{pane_ps_state}'
check progress-only-when-busy '' '#{pane_ps_progress}'

# the feature detection query is answered with the same body, before the
# primary device attributes reply that follows it
cat >"$TMP.py" <<'EOF'
import os, select, sys, termios, tty
fd = os.open('/dev/tty', os.O_RDWR)
old = termios.tcgetattr(fd)
tty.setraw(fd)
try:
    os.write(fd, b'\x1b]7501;?\x1b\\\x1b[c')
    buf = b''
    while True:
        r, _, _ = select.select([fd], [], [], 1.0)
        if not r:
            break
        buf += os.read(fd, 256)
        if b'\x1b[?' in buf and buf.endswith(b'c'):
            break
finally:
    termios.tcsetattr(fd, termios.TCSADRAIN, old)
ok = buf.startswith(b'\x1b]7501;?\x1b\\') and b'\x1b[?' in buf
open(sys.argv[1], 'w').write('ok' if ok else repr(buf))
EOF
$TMUX send-keys -t "$P" "python3 -I $TMP.py $TMP" Enter
sleep 1.5
if [ "$(cat "$TMP")" != "ok" ]; then
	echo "query: expected reply then DA but got '$(cat "$TMP")'"
	exit 1
fi

# window_ps_state is the most pressing state over the window's panes
$TMUX split-window -t "$P" -d
P2=$($TMUX list-panes -F '#{pane_id}' | grep -v "^$P\$")
$TMUX send-keys -t "$P2" "printf '\\033]7501;state=blocked\\033\\\\'" Enter
sleep 0.2
check window-most-pressing blocked '#{window_ps_state}'
$TMUX kill-pane -t "$P2"

report 'state=clear'
check clear '' '#{pane_ps_state}'

# process exit drops working but keeps done
report 'state=working'
$TMUX send-keys -t "$P" exit Enter
sleep 0.2
check exit-drops-working '' '#{pane_ps_state}'
$TMUX respawn-pane -k -t "$P"
sleep 0.2
report 'state=done'
$TMUX send-keys -t "$P" exit Enter
sleep 0.2
check exit-keeps-done done '#{pane_ps_state}'

$TMUX respawn-pane -k -t "$P"
sleep 0.2
$TMUX set-hook -g pane-program-status "set -gF @hook 'fired:#{hook_pane}'"
report 'state=idle'
check hook "fired:$P" '#{@hook}'

exit 0
