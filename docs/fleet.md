# Running a fleet

One agent with memory is a colleague who remembers. Several is a fleet, and a
fleet needs exactly three things Imago did not have: a way for an agent to
**report** cheaply, a rule for how one agent **starts** another without losing
the guarantees, and one agent whose job is to **hold the whole picture**.

That is all this document adds. There is no queue, no message bus, no
coordinator process — and [the last section](#what-this-deliberately-does-not-do)
argues each omission.

## The shape

```
~/.imago/
├── chief/
│   ├── MEMORY.md        the index
│   ├── fleet            one specialist per line
│   ├── brief.md         what the chief tells you
│   └── <facts>.md
├── research/
│   ├── MEMORY.md
│   ├── brief.md         what research tells the chief
│   └── <facts>.md
└── scout/
    └── ...
```

Specialists run on a schedule and write briefs. The chief reads the briefs and
talks to you. You talk to whoever you like. Nothing in the fleet starts anything
else.

## The brief

`~/.imago/<name>/brief.md`. **At most five lines, first line the date,
overwritten every run — never appended.**

```
2026-08-22
shipped: re-checked the four known findings; two still open
stuck:   cannot read ~/work/api — permission denied since Tuesday
needs you: decide whether the hook failure is worth fixing or muting
```

Five lines because a chief that has to read six full contexts is not cheaper than
you reading them yourself. The brief is what makes a fleet scale: the chief reads
*n × 5 lines*, not *n contexts*.

Rules that keep it honest:

- **Written by the agent that owns the directory.** One writer per memory
  directory still holds — the chief reads briefs, it never writes them.
- **Not a fact.** It carries no frontmatter, it is excluded from the 12,000-char
  budget, and it is not listed in `MEMORY.md`. It is a report; facts are what the
  agent learned. `tools/check` treats it as neither.
- **Part of the deliverable, every run.** A specialist that ran and wrote no brief
  has not reported. Facts are written *in addition*, only when something was
  learned — most runs learn nothing.

The brief is also the answer to requirement 3 in [proactivity.md](proactivity.md):
an unattended run has to land somewhere durable, and now that somewhere has a
name.

## The fleet file

`~/.imago/<chief>/fleet`, one name per line, `#` for comments:

```
# reports to the chief
research
scout
```

It lives in the memory tree rather than the definition's frontmatter for the same
reason the operating mode does: a file carries no risk of a harness rejecting an
unrecognised key, and this is state about the fleet, not identity. Explicit over
implicit — the chief's mandate names who reports to it.

`tools/new-agent chief --memory deliverable --fleet research,scout` writes it.

## What starts a specialist — and it is never the chief

Three things wake an agent, and the chief is none of them:

| | What it is | Imago has it |
|---|---|---|
| **A schedule** | a crontab line, fired whether or not anything happened | yes — [proactivity.md](proactivity.md) |
| **An event** | something appeared: a file, a message, a commit | **no** — see below |
| **You** | `claude --agent scout --add-dir ~/.imago` | yes |

This is not a limitation to work around; it is what the working fleets actually
do. In the accounts this repo draws on, the chief **messages the others and asks
for updates** — the routine that makes a specialist run belongs to the specialist,
and the brief travels *upward*. Nobody describes a chief that starts anything.

It is also the safer shape by some distance. Starting a session means running a
command, which means giving the chief a shell — and a shell can launch a child
with *more* permission than the parent has, which is precisely the escalation the
harness refuses between sessions. A rule in a prompt is not a substitute for not
having the capability.

So the chief's example ships with no `Bash`, and there is no dispatch command in
this document. If you want one anyway, that is your call: grant `Bash`, scope it
in your permissions to the `claude` command rather than to a shell, and know that
you have opened the door above.

**Events are the real gap.** "Every time a recording lands in this folder,
transcribe it and draft the posts" is the shape most of the useful proactivity in
practice takes, and Imago has nothing for it — no watcher, no trigger. Today you
approximate it with a schedule that checks. It is worth knowing that is an
approximation.

## The chief is a default channel, not a router

**Talk to any specialist directly whenever you want depth:**

```bash
claude --agent research --add-dir ~/.imago
```

Give it feedback, argue with it, then tell it to update its brief. The chief will
read that brief at its next start. This is the design, not a workaround — a chief
that every instruction must pass through is a context hop that adds latency and
loses fidelity, which is exactly the orchestrator [design.md](design.md) declines.

## Why the chief must stay idle

An agent's attention is its turn. A message arriving while an agent works is
queued until its next turn, or aborts it — neither is conversation. So an agent
that is working is an agent you cannot talk to.

The chief stays reachable **only because it does not do the work**. That is the
load-bearing reason for the five-line brief and for the chief's refusal to do a
specialist's job. If you give the chief real work, your one conversational agent
goes silent for minutes at a time and the fleet feels broken.

It is also why an interrupt is expensive here. Under the `deliverable` shape the
run's only durable output is written at the end, so aborting a specialist
mid-flight destroys what it learned — the same silent loss as a skipped write,
triggered by you instead of by the budget.

## Scheduling

Cron, as always — [proactivity.md](proactivity.md) has the full argument. A
specialist gets a crontab line; the chief does not, because you are its trigger.

**What the line says matters more than how often it fires.** A schedule decides
*when* an agent wakes; the prompt decides whether it is an errand-runner or a
colleague. `"Review this project's setup"` is a narrow standing order and the
right starting point. The open form — *look across everything you have and do
what is worth doing* — is what the mature accounts describe, and it only works on
top of a context substrate rich enough to make the judgement: goals written down,
history, the things nobody wrote in any document. On thin context the same prompt
produces confident, expensive noise. [proactivity.md](proactivity.md) requires the
narrow form, and that section says what the requirement is contingent on.

```cron
0 9 * * 1  cd /path/to/project && echo "Review this project's setup." | /usr/local/bin/claude -p --agent scout --allowedTools Write Edit --add-dir ~/.imago >> ~/.imago/scout.log 2>&1
```

Match the interval to how fast the thing being watched changes. Over-frequent
scheduling is the most common way a useful agent becomes noise, and — because
every run costs tokens whether or not it finds anything — the most common way one
becomes expensive.

## Cost, and which model

Everything here runs under your Claude Code subscription: `claude -p` is the same
binary with the same login. **The usage limit is shared across every session,
cron runs included** — a fleet spends from the same budget you do. Specialists
should run on cheaper models (`--model haiku` or `sonnet`); the chief is the one
that benefits from the strongest.

One trap worth knowing: if `ANTHROPIC_API_KEY` is set in your environment, the CLI
bills the API instead of your subscription, silently. An `export` left in a shell
profile for some other project is enough to do it.

## Optional: the live channel

If your build has cross-session messaging (`ListAgents` / `SendMessage`), a
specialist can notify a chief that happens to be open, and the message arrives at
the chief's next turn without interrupting it. Useful, and worth knowing what it
is not:

- it reaches **live sessions only** — a `-p` run that has exited is not reachable,
  and a chief that is closed receives nothing;
- a message lives in the receiver's transcript. **It is not a record.**

So the file is the contract and the message is a courtesy. A brief written to disk
survives the 4am run nobody was awake for; a message sent to a chief that was not
running is gone. Build on the file; use the message to make a live chief feel
alive.

Sessions are named after their working directory, so a specialist always launched
from the same place has a stable, addressable name.

## Start with two

The ladder that works, from the practitioner accounts this repo is built on:

1. one agent;
2. one agent acting **on a schedule**, without being asked;
3. **two agents, one reading what the other wrote.**

Stop at three until it has earned its keep for a month. Every account of a working
fleet says the same thing about what goes wrong: not the models, not the wiring —
**agent creep**. An agent per idea, each one burning context and returning
nothing. The discipline that prevents it is that an agent is only created after
the work already exists: the chief does the job once, you review the output, and
*then* it becomes a specialist. Never from a job description.

## What this deliberately does not do

- **No queue.** A queue needs a daemon, and a daemon is the runtime this repo does
  not have. The files are the queue.
- **No agent starting another agent** — not the chief, not a specialist. If
  research needs scout, that goes through you or through a schedule. Agents
  starting agents is how a fleet spends a budget overnight with nobody able to
  say why, and it is the shape that turns one over-broad prompt into a fan-out.
- **No event triggers.** Named above as a real gap rather than a decision.
- **No agent-to-agent mailbox in place of files.** See the section above: a
  message does not survive the run.
- **No chief with authority.** It holds the broad context and it is the default
  channel. It cannot do anything a specialist cannot, it does not approve their
  work, and it is not in the way.
- **No UI.** `cat ~/.imago/*/brief.md`.

When you genuinely need a queue, always-on operation across platforms, or agents
that coordinate without you, that is the point to move to one of the frameworks
in the README's scope section — with a memory model you already understand.
