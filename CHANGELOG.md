# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [0.1.4] - 2026-08-22

### Added
- **Graduation — the second exit from memory.** A `lesson` confirmed three times
  (a new `confirmations:` field) or signed off once by the operator is promoted
  into the definition's new `## Standing rules` section as a dated line, and
  deleted from memory. In memory a lesson is text the agent must notice, judge
  relevant and re-apply every run; in the definition it is what the agent *is*.
  `tools/check` reports which lessons have earned it
- **`## Autonomy`** in every definition: what it does without asking, what it
  never does, and when it escalates — with the standing preference for removing
  the tool over writing the rule, since a capability never granted has no rule to
  forget
- **"What breaks if you do not run"** as the opening line of a mandate. An agent
  whose absence breaks nothing should not exist, and this is where that question
  gets asked before the agent is built
- `tools/check` warns on a missing `## Autonomy`, a mandate that never says what
  breaks, and a standing rule with no date

### Changed
- The operator, not the agent, edits the definition. An agent that can rewrite
  its own definition can rewrite its own refusals, so that capability is
  deliberately absent rather than withheld

## [0.1.3] - 2026-08-22

### Changed
- **The chief of staff no longer starts anything, and ships without `Bash`.**
  v0.1.2 had it dispatch specialists as background sessions. Re-reading the
  practitioner accounts the design comes from, that is not what a chief does:
  it *messages* the others and asks for updates, while what makes a specialist
  run is its own schedule. It is also the safer shape — an agent that can run a
  command can hand a child more permission than it holds itself, which is the
  escalation the harness refuses between sessions and which a rule in a prompt
  does not prevent
- **The narrow-mandate requirement is now stated as conditional**, because it is
  a consequence rather than a principle: an open mandate is exactly as good as
  the context underneath it. Keep it narrow while the context is a memory
  directory; widen it in step with what the agent can actually read

### Added
- `proactivity.md` separates **what wakes an agent** (schedule, event, you) from
  **what its prompt says**, and states plainly that Imago has **no event
  triggers** — a gap, not a decision. The most useful automations in practice
  are event-shaped, and a schedule that polls for the same condition pays for
  every empty run

## [0.1.2] - 2026-08-22

### Added
- `examples/chief.md` — a second worked agent: a chief of staff that reads its
  specialists' briefs, dispatches them as background sessions, and holds the
  fleet's own memory
- `docs/fleet.md` — running more than one agent: the brief, the `fleet` file,
  dispatch as a process rather than a subagent, cost, and what it deliberately
  does not do
- The `SessionStart` hook now injects the agent's index, **how full its memory
  is as a percentage**, facts missing from the index, and the fleet's briefs.
  "Consolidate above 80%" was previously a rule no agent could evaluate
- `brief.md` — five lines, overwritten every run, outside the memory budget:
  what an agent reports to its chief
- `tools/new-agent --fleet a,b` writes the `fleet` file
- `tools/check` verifies the brief contract and the `fleet` file

### Changed
- The `Stop` hook now records a run that ended without writing anything, and the
  `SessionStart` hook raises it once at the next run. A skipped write was
  previously permanent *and* silent
- The non-goal "no coordinator agent" is now stated as what it always meant: the
  chief's *authority* is rejected, its *position* is not

## [0.1.1] - 2026-08-22

### Changed
- A new README banner image

## [0.1.0] - 2026-08-21

Initial release.

### Added
- The template itself: agent scaffolding (`tools/new-agent`), memory
  verification (`tools/check`), scaffolding sources (`templates/`), and the
  worked example agent, Toby (`examples/toby.md`)
- Normative docs: the design rationale (`docs/design.md`), the memory
  contract (`docs/memory-spec.md`), and running unattended
  (`docs/proactivity.md`)
- `Stop`-hook scripts so a session-level agent's memory write can be
  enforced mechanically, and the bounded-memory rationale for why memory is
  curated rather than a journal
- `tools/check` now flags facts that read as instructions rather than
  observations, and rejects absolute paths in facts
- A project banner in the README

### Fixed
- Local agents are scheduled with the operating system's own cron, not a
  `/schedule` command
- Corrected the outdated claim that all of Claude Code's own scheduling
  runs in the cloud — Desktop's local scheduled tasks are real and local
  (#2)

### Changed
- Memory moved to `~/.imago`, kept separate from `~/.claude/agents/`, and
  the three agent launch modes documented
- The deliverable memory-write rule bound to a unit of work rather than
  every turn, with agents given `Edit` access
- Memory can no longer choose its own write target
- README reworked: scoped against OpenClaw and Hermes, clarified that the
  real test is the second run rather than the read-back, and corrected the
  memory location, script count, and reference table
