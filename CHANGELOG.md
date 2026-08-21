# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

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
