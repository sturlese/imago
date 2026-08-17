#!/usr/bin/env bash
# Imago SessionStart hook — drops a marker so the Stop hook can tell whether the
# agent wrote anything during this session.
#
# Pairs with imago-stop.sh. Optional: it is a backstop under the `deliverable`
# memory shape, not a replacement for it. See docs/proactivity.md.
#
# Install by adding both hooks to ~/.claude/settings.json:
#
#   "hooks": {
#     "SessionStart": [{"hooks": [{"type": "command",
#        "command": "~/.imago/hooks/imago-session-start.sh"}]}],
#     "Stop":         [{"hooks": [{"type": "command",
#        "command": "~/.imago/hooks/imago-stop.sh"}]}]
#   }
#
# Both no-op unless the session is running as an Imago agent, so ordinary
# sessions and non-Imago agents are unaffected.

set -u
input=$(cat 2>/dev/null || true)

agent=$(printf '%s' "$input" | python3 -c \
  'import json,sys;print((json.load(sys.stdin).get("agent_type") or "").strip())' 2>/dev/null) || exit 0
[ -n "$agent" ] || exit 0

memory="${IMAGO_MEMORY:-$HOME/.imago}/$agent"
[ -d "$memory" ] || exit 0   # not an Imago agent — nothing to enforce

touch "$memory/.imago-session-start" 2>/dev/null || true
exit 0
