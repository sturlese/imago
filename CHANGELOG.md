# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

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
