# Running unattended

An agent that only runs when you summon it barely needs memory — you would remember what it told you. Memory earns its keep when the agent fires on a schedule and accumulates across runs nobody watched.

Imago does not ship a scheduler. It provides the **contract an agent must satisfy before it is safe to schedule**, because unattended agents fail differently from interactive ones — and the launch command, which is less obvious than it looks.

## Three ways to run an agent, and only one of them schedules

**As a subagent.** Open Claude Code and ask the session to use the agent by name. The main session dispatches it, the agent returns its result, and the session carries on — the orchestrator stays in charge and the agent is an errand it ran. Convenient, but there is no way to invoke this from cron, and **session hooks do not fire for a subagent**, so nothing mechanical can verify it wrote anything.

**As an interactive session.** `claude --agent <name> --add-dir ~/.imago` starts an ordinary interactive session that *is* the agent: you talk to Toby, he answers as Toby, and you can go back and forth for as long as you like. This is the mode that feels like working with a colleague rather than dispatching a function, and it is the best way to develop a personality — you find out immediately whether the refusals hold under pressure. Writes are approved through the normal permission prompt, which is fine when you are sitting there.

**As a non-interactive session.** The same thing with `-p`: one shot, prints, exits. This is the form that schedules, and — like the interactive form — the one where the `Stop` hook fires, which is what makes mechanical enforcement of the memory write possible at all ([design.md](design.md)).

```bash
echo "Review this project's Claude Code setup." | \
  claude -p --agent toby --allowedTools Write Edit --add-dir ~/.imago
```

Every part of that line is load-bearing:

- **`-p`** runs non-interactively and prints the result — required for anything scheduled.
- **`--add-dir ~/.imago`** grants access to the memory directory. **Writes outside the working directory are denied by default**, so without this the agent cannot write its memory. This is the single most common way an Imago agent silently accomplishes nothing.
- **`--allowedTools Write Edit`** grants the write itself. `--add-dir` opens the directory; this opens the tools. In interactive mode you would be prompted and could approve; under `-p` there is nobody to ask, so an ungranted write is simply denied.
- **The prompt goes through stdin.** `--add-dir` and `--allowedTools` are variadic — a prompt written as a trailing argument gets swallowed as another value for whichever flag came last, and the command fails with "Input must be provided either through stdin or as a prompt argument".

`--bg` starts it in the background instead, and `claude agents` manages background sessions.

Once that command works from your shell, it needs a scheduler to fire it. Two of them actually run locally — a cloud one does not.

**Your operating system's cron is the plainest of the two.** On macOS or Linux that is `crontab -e`:

```cron
0 9 * * 1  cd /path/to/project && echo "Review this project's Claude Code setup." | /usr/local/bin/claude -p --agent toby --allowedTools Write Edit --add-dir ~/.imago >> ~/.imago/toby.log 2>&1
```

Use absolute paths for `claude` — cron's `PATH` is minimal — and redirect the output somewhere, since nothing is attached to read it.

**Claude Code Desktop's local scheduled tasks are the other.** A task created from the Routines page (or by asking a Desktop session to "set up a daily review at 9am") runs on your machine, persists across restarts, and fires a fresh session as often as once a minute — no shell, no crontab. Its prompt lives in `~/.claude/scheduled-tasks/<task-name>/SKILL.md`; schedule, working folder, model and permission mode are set through the Edit form. It only fires while the Desktop app is open and the machine is awake, and a missed run gets one catch-up on wake rather than a backlog.

The trap is that a task's Instructions field ("use the toby agent to review...") dispatches Toby **as a subagent of the task's own session** — the weakest of the three launch modes above, with no `Stop` hook and nothing that verifies the memory write. To get the session-level mode instead, the task's working folder needs its own `.claude/settings.json` naming the agent and granting it the memory tree, so the task's session *is* Toby rather than a session that calls him:

```json
{
  "agent": "toby",
  "permissions": {
    "additionalDirectories": ["~/.imago"],
    "allow": ["Write(~/.imago/**)", "Edit(~/.imago/**)"]
  }
}
```

This is unverified against a live run as of this writing — confirm with **Run now** before trusting it unattended, the same way you would verify any new launch command.

**Cloud routines still do not fit.** A cloud session has neither your agent definition in `~/.claude/agents/` nor its memory in `~/.imago/` — both are on your machine, so the agent would start with no identity and nothing to remember. **In-session cron (`/loop`) still does not fit either** — jobs created inside a session live in memory, vanish when the session exits, and enqueue a prompt into *that* session rather than launching a chosen agent.

A locally-defined agent with local memory is scheduled locally, by either of the two schedulers above. If you want the cloud instead, the memory has to move somewhere both sides can reach — which is a different architecture, and a good reason to leave the fleet on one machine until you actually need otherwise.

Imago wraps none of this deliberately: a scheduler wrapper here would date badly and would turn a convention into an orchestrator.

## Grant the narrowest thing that works

`--add-dir ~/.imago` grants exactly the memory tree. Resist the temptation to grant `~/.claude` instead so that memory can live beside the definitions: that hands the agent its own configuration, every other agent's definition, and your settings. Least privilege is the reason memory lives in a separate tree at all.

If an agent's mandate genuinely requires reading elsewhere, grant that directory explicitly too, and have the agent **say when a read was denied**. A run that quietly skipped half its mandate is indistinguishable from a run that found nothing.

## Memory and proactivity are two halves of one design

They are usually presented as separate features. They are not:

- **Proactivity is what makes memory worth having.** Unattended runs are exactly the ones you did not observe, so the agent's own record is the only record.
- **Memory is what makes proactivity tolerable.** A scheduled agent without memory reports the same finding every single run until you mute it. The `rejected` and `pattern` fact types exist for this.
- **Unattended running is where the write path gets dangerous.** In an interactive session a skipped memory write might catch your eye. On a cron job at 4am it will not, and you will discover it weeks later as an agent that has apparently learned nothing.

## The five requirements

Before scheduling an agent, all five must hold.

### 1. The memory write cannot be discretionary

The shape must be `deliverable` or `caller` ([design.md](design.md)). "Update your memory when you're done" is not merely discouraged here — it is **disqualifying**, because the failure is silent and permanent.

### 2. It cannot ask questions

An unattended agent that ends a turn with "would you like me to continue?" blocks until the run is reclaimed, and the whole run is wasted. It needs to be told plainly that nobody can answer, and given licence to decide:

> You are running unattended. Nobody is watching and nobody can answer a question. For minor decisions, choose a reasonable option and record what you chose. Do not end a turn with a question or a proposal — if it follows from your mandate and is reversible, do it.

The failure is not that the agent is being polite; it is that the harness has no one to route the question to.

### 3. Output has to land somewhere durable

Interactive agents report to you. Unattended agents report to nobody — nothing is reading stdout at 4am. If the run does not write a file, the run produced nothing. This is the same requirement as #1 seen from the other side, which is why `deliverable` fits scheduled agents so naturally: the durable output and the memory write are the same act.

### 4. The mandate has to be narrow

An open mandate plus a schedule burns budget producing nothing. "Look for anything interesting" is not a mandate. A schedulable agent has a specific trigger and a bounded job: *what* it looks at, *what* counts as a finding, and *when* to stop looking.

### 5. It must not repeat itself

This is what memory is for, and it needs to be explicit in the definition rather than assumed:

> Before reporting a finding, check your memory. If you have reported it before, do not report it again — add an occurrence to the existing `pattern` fact instead. If it is something that was rejected, do not re-propose it unless the reason for the rejection no longer holds, and say what changed.

The comparison this instruction asks for is only as reliable as what a `pattern` fact is keyed on. "The same problem I found before" is a judgment call the model can get wrong in either direction; a stable handle it can match against literally — a file path plus line, a rule ID, a hostname — is not. Give the agent something concrete to key its patterns on wherever the finding has one.

Without this an agent is technically correct and practically unbearable.

## Declaring the mode

Imago adds no frontmatter field for this. The declaration goes in the body of the definition, as a standard section:

```markdown
## Operating mode

`unattended` — Nobody is watching and nobody can answer you. Do not ask
questions; for minor decisions choose and record the choice. Your run has
produced nothing until you have written to `~/.imago/toby/`. Before
ending your turn, confirm that you have.
```

The point of putting it in the body is that **declaring the mode and instructing the behaviour are the same act.** It is not metadata for a tool to interpret — it is prompt text the model reads, which is where the behaviour has to come from anyway. As a side benefit, body text carries no risk of a harness rejecting an unrecognised frontmatter key.

`tools/check` verifies the section exists and, when the mode is `unattended`, that the memory shape is not discretionary.

## Optional: let the harness enforce the write

Because a session-level agent gets a `Stop` event, a hook can refuse to end the session until the memory changed. This is the enforcement that a subagent cannot have, and it is the strongest of the three — a hook does not have a bad day.

Two scripts ship in [`tools/hooks/`](../tools/hooks/): `imago-session-start.sh` drops a marker, `imago-stop.sh` compares against it and blocks once if nothing was written. Copy them somewhere stable and register both:

```json
{
  "hooks": {
    "SessionStart": [{"hooks": [{"type": "command", "command": "~/.imago/hooks/imago-session-start.sh"}]}],
    "Stop":         [{"hooks": [{"type": "command", "command": "~/.imago/hooks/imago-stop.sh"}]}]
  }
}
```

Both no-op unless the session is running as an agent that has a memory directory, so **ordinary sessions and non-Imago agents are unaffected** — the hook reads `agent_type` from the payload Claude Code provides. The Stop hook blocks at most once (it honours `stop_hook_active`), so a genuinely empty run ends on the second pass rather than hanging.

Treat it as a backstop under `deliverable`, not a replacement for it: a hook can check *that* something was written, never *what*, and it does nothing at all for the subagent form.

## Choosing a cadence

Match the interval to how fast the thing being watched actually changes. An agent watching your own tooling has nothing new to say hourly; daily or weekly is usually right. Over-frequent scheduling is the most common way a useful agent becomes noise — and because each run costs tokens whether or not it finds anything, it is also the most common way one becomes expensive.

Start with a single agent on a slow cadence, read what it produces for a week, then adjust. A fleet of scheduled agents built before any of them has proven useful is a fleet of scheduled agents nobody reads.
