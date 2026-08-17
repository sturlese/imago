# Running unattended

An agent that only runs when you summon it barely needs memory — you would remember what it told you. Memory earns its keep when the agent fires on a schedule and accumulates across runs nobody watched.

Imago does not ship a scheduler. Claude Code has one: `/schedule` creates cloud agents on a cron cadence, and `/loop` handles recurring work inside a session. What Imago provides is the **contract an agent must satisfy before it is safe to schedule**, because unattended agents fail differently from interactive ones.

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

Without this an agent is technically correct and practically unbearable.

## Declaring the mode

Imago adds no frontmatter field for this. The declaration goes in the body of the definition, as a standard section:

```markdown
## Operating mode

`unattended` — Nobody is watching and nobody can answer you. Do not ask
questions; for minor decisions choose and record the choice. Your run has
produced nothing until you have written to `~/.claude/memory/toby/`. Before
ending your turn, confirm that you have.
```

The point of putting it in the body is that **declaring the mode and instructing the behaviour are the same act.** It is not metadata for a tool to interpret — it is prompt text the model reads, which is where the behaviour has to come from anyway. As a side benefit, body text carries no risk of a harness rejecting an unrecognised frontmatter key.

`tools/check` verifies the section exists and, when the mode is `unattended`, that the memory shape is not discretionary.

## Choosing a cadence

Match the interval to how fast the thing being watched actually changes. An agent watching your own tooling has nothing new to say hourly; daily or weekly is usually right. Over-frequent scheduling is the most common way a useful agent becomes noise — and because each run costs tokens whether or not it finds anything, it is also the most common way one becomes expensive.

Start with a single agent on a slow cadence, read what it produces for a week, then adjust. A fleet of scheduled agents built before any of them has proven useful is a fleet of scheduled agents nobody reads.
