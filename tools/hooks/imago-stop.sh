#!/usr/bin/env bash
# Imago Stop hook — refuse to end an agent session that recorded nothing.
#
# This is the harness-level backstop under the `deliverable` memory shape: the
# prompt says the memory write is the task, and this makes the harness agree. It
# only works when the agent IS the session (`claude --agent <name>`); a subagent
# dispatched from a session gets no Stop event of its own.
#
# It no-ops unless all of these hold, so ordinary sessions are unaffected:
#   - the session runs as an agent (`agent_type` in the hook payload)
#   - that agent has a memory directory under ~/.imago
#   - nothing in that directory changed during the session
#
# It blocks at most once. On the second pass it lets the session end — but it
# writes `.imago-last-run-empty` first, and imago-session-start.sh raises that at
# the agent's next run, once. A skipped write is otherwise permanent AND silent,
# which is the failure docs/design.md is about; this makes it loud at the moment
# a read depends on it.
#
# Pairs with imago-session-start.sh, which drops the marker this compares against.
# See docs/proactivity.md for installation.

set -u
input=$(cat 2>/dev/null || true)

agent=$(printf '%s' "$input" | python3 -c \
  'import json,sys;print((json.load(sys.stdin).get("agent_type") or "").strip())' 2>/dev/null) || exit 0
[ -n "$agent" ] || exit 0

memory="${IMAGO_MEMORY:-$HOME/.imago}/$agent"
[ -d "$memory" ] || exit 0   # not an Imago agent — nothing to enforce

marker="$memory/.imago-session-start"
[ -f "$marker" ] || exit 0   # no marker: SessionStart hook not installed, stay quiet

# Did anything in the memory directory change since this session started?
changed=$(find "$memory" -maxdepth 1 -name '*.md' -newer "$marker" 2>/dev/null | head -1)
[ -n "$changed" ] && exit 0

# Loop safety: block at most once. Claude Code sets stop_hook_active when a stop
# was already blocked, so the second pass lets the session end — but it does not
# let the loss go quiet. Record it, and imago-session-start.sh raises it at the
# next run, once. This is the only way a skipped write reaches anyone: the run
# that skipped it is over, and nobody was watching it at 4am.
if printf '%s' "$input" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
  date -u +%Y-%m-%dT%H:%M:%SZ > "$memory/.imago-last-run-empty" 2>/dev/null || true
  exit 0
fi

cat <<JSON
{"decision":"block","reason":"This session ran as the '$agent' agent and wrote nothing to $memory. Under the deliverable memory shape the run has produced nothing until the memory is updated. Record what you learned as a fact file and update MEMORY.md, or — if there was genuinely nothing new — consolidate the existing facts. Then stop."}
JSON
exit 0
