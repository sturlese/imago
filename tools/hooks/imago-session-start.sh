#!/usr/bin/env bash
# Imago SessionStart hook — put the agent's memory in front of it before it works.
#
# The definition asks the agent to read `MEMORY.md` first. That is an instruction
# nothing verifies, which is the failure this repo is organised around — so this
# hook reads it instead, and hands the agent four things it cannot work out for
# itself:
#
#   1. the index, verbatim, so the read is guaranteed rather than requested;
#   2. how full the memory is, as a percentage — "consolidate above 80%" is not a
#      rule the model can evaluate without summing characters across a directory;
#   3. facts on disk that are missing from the index, which would otherwise never
#      be found again;
#   4. the fleet's briefs, for an agent that has a `fleet` file — so a chief of
#      staff opens already knowing what its specialists reported.
#
# It also surfaces, once, a previous run that recorded nothing (see
# imago-stop.sh). A silent loss becomes loud at the moment a read depends on it.
#
# Pairs with imago-stop.sh. Install by adding both to ~/.claude/settings.json:
#
#   "hooks": {
#     "SessionStart": [{"hooks": [{"type": "command",
#        "command": "~/.imago/hooks/imago-session-start.sh"}]}],
#     "Stop":         [{"hooks": [{"type": "command",
#        "command": "~/.imago/hooks/imago-stop.sh"}]}]
#   }
#
# Both no-op unless the session is running as an Imago agent, so ordinary
# sessions and non-Imago agents are unaffected. Session-scoped, like every hook:
# a subagent dispatched by name gets none of this, which is one more reason to
# run an agent as its own session. See docs/proactivity.md and docs/fleet.md.

set -u
input=$(cat 2>/dev/null || true)

agent=$(printf '%s' "$input" | python3 -c \
  'import json,sys;print((json.load(sys.stdin).get("agent_type") or "").strip())' 2>/dev/null) || exit 0
[ -n "$agent" ] || exit 0

root="${IMAGO_MEMORY:-$HOME/.imago}"
memory="$root/$agent"
[ -d "$memory" ] || exit 0   # not an Imago agent — nothing to inject

# The baseline imago-stop.sh compares against: did anything change during this run?
touch "$memory/.imago-session-start" 2>/dev/null || true

IMAGO_AGENT="$agent" IMAGO_DIR="$memory" IMAGO_ROOT="$root" python3 <<'PY' 2>/dev/null || exit 0
import json, os

agent = os.environ["IMAGO_AGENT"]
mem = os.environ["IMAGO_DIR"]
root = os.environ["IMAGO_ROOT"]
try:
    budget = int(os.environ.get("IMAGO_BUDGET") or 12000)
except ValueError:
    budget = 12000

# brief.md is a report, not a fact: it is written every run, read by another
# agent, and would otherwise spend the budget that exists to force curation.
NOT_A_FACT = {"MEMORY.md", "brief.md"}


def read(path):
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            return f.read()
    except OSError:
        return None


def facts(directory):
    try:
        names = os.listdir(directory)
    except OSError:
        return []
    return sorted(n for n in names if n.endswith(".md") and n not in NOT_A_FACT)


alerts = []   # things that need acting on, said first
parts = []    # the memory itself

# --- a previous run that recorded nothing, said once ------------------------
marker = os.path.join(mem, ".imago-last-run-empty")
when = read(marker)
if when is not None:
    stamp = when.strip() or "an earlier run"
    alerts.append(
        f"! Your previous run ({stamp}) ended without recording anything.\n"
        "  If that was a loss rather than a genuinely empty run, re-derive what it\n"
        "  should have written before continuing. You are seeing this once.")
    try:
        os.remove(marker)
    except OSError:
        pass

# --- the index, and how full it is ------------------------------------------
index = read(os.path.join(mem, "MEMORY.md"))
total = 0
for name in facts(mem) + ["MEMORY.md"]:
    try:
        total += os.path.getsize(os.path.join(mem, name))
    except OSError:
        pass

pct = (total / budget) if budget else 0
header = f"MEMORY — {agent}  [{pct:.0%} — {total:,}/{budget:,} chars]"
if pct >= 1.0:
    header += "  OVER BUDGET"
elif pct >= 0.80:
    header += "  CONSOLIDATION DUE"

body = [header]
if pct >= 0.80:
    body.append(
        "Consolidating is part of this run: merge facts that are variations on one\n"
        "idea, delete what has since been contradicted, compress what survives, and\n"
        "rebuild MEMORY.md to match.")
body.append(
    "This is your index, read for you. Open the facts whose hooks are relevant to\n"
    "the task in front of you — not all of them by reflex; the hooks exist so you\n"
    "can rule things out.")
if index is None:
    body.append("(No MEMORY.md on disk. Create it before filing a fact.)")
else:
    body.append(index.strip() or "(The index is empty — you have not filed anything yet.)")
parts.append("\n\n".join(body))

# --- facts nobody will find again -------------------------------------------
if index is not None:
    listed = set()
    for line in index.splitlines():
        start = line.find("](")
        if start != -1:
            end = line.find(")", start + 2)
            if end != -1:
                listed.add(os.path.basename(line[start + 2:end]))
    orphans = [f for f in facts(mem) if f not in listed]
    if orphans:
        alerts.append(
            f"! {len(orphans)} fact(s) on disk are not listed in MEMORY.md: "
            f"{', '.join(orphans)}\n"
            "  A fact that is not in the index will not be found again. Add them in\n"
            "  this run.")

# --- the fleet's briefs ------------------------------------------------------
fleet = read(os.path.join(mem, "fleet"))
if fleet is not None:
    members = [ln.strip() for ln in fleet.splitlines()]
    members = [m for m in members if m and not m.startswith("#")]
    if members:
        lines = ["FLEET — what your specialists last reported."]
        for member in members:
            brief = read(os.path.join(root, member, "brief.md"))
            if brief is None:
                lines.append(f"\n{member}: no brief on file. It has not reported since you last "
                             "looked, or it has never run.")
            else:
                lines.append(f"\n{member}:\n{brief.strip()}")
        lines.append(
            "\nA brief is what a specialist reported, not what you observed. If one is\n"
            "missing, say it is missing — do not speak for an agent that has not reported.")
        parts.append("\n".join(lines))

blocks = alerts + parts
if blocks:
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": "\n\n".join(blocks)}}))
PY
exit 0
