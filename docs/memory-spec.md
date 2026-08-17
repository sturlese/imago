# Memory specification

Normative. This is the contract an Imago agent's memory satisfies, and what `tools/check` verifies. The reasoning behind it is in [design.md](design.md).

## Location

```
~/.claude/agents/<name>.md          the agent definition (Claude Code reads this)
~/.claude/memory/<name>/            the agent's memory
├── MEMORY.md                       index — one line per fact
├── <fact-slug>.md                  one fact per file
└── ...
```

One directory per agent. Never shared between agents: two agents writing the same directory reintroduces every concurrency problem this design avoids, and their working state genuinely differs even when their knowledge overlaps.

Memory directories live under `~/.claude/`, never inside a checkout of this template.

## The index

`MEMORY.md` is what the agent scans to decide which facts to open. One line per fact, no frontmatter, and nothing else in the file:

```markdown
# Memory — toby

- [Skill lint fails on periods in page names](lint-period-wikilinks.md) — the vault linter reads a `.` in a wikilink as an attachment path
- [Marc rejects per-agent vaults](rejected-vault-per-agent.md) — proposed 2026-08-17, turned down as overkill
```

Format: `- [Title](filename.md) — one-line hook`. The hook exists so the agent can rule a fact out without opening it.

Cap the index at **60 lines**. An index longer than that is a sign the memory needs consolidating rather than a bigger index.

## Facts

One fact per file. A file holds a single idea — if it needs an "additionally" it is two facts.

```markdown
---
name: lint-period-wikilinks
description: The vault linter treats a period inside a wikilink as an attachment path
type: lesson
created: 2026-08-17
---

Page titles containing a period break wikilink resolution in `vault_lint.py`: any
link whose target contains `.` and does not end in `.md` is classified as an
attachment embed, so `[[Allie K. Miller]]` is reported as a dead link.

**Why:** the check exists to catch broken image embeds, but it uses "contains a
period" as its test instead of "ends in a known file extension".

**How to apply:** when creating pages, avoid periods in titles and put the
variant in `aliases`. When the linter reports a dead link that clearly exists,
check for a period before investigating anything else.
```

### Frontmatter

| Field | Required | Notes |
|---|---|---|
| `name` | yes | kebab-case, matches the filename without `.md` |
| `description` | yes | one line; this is what goes in the index hook |
| `type` | yes | one of the four below |
| `created` | yes | `YYYY-MM-DD` |
| `superseded_by` | no | slug of the fact that replaced this one, when keeping the old one is useful |

### Types

| Type | For | Body shape |
|---|---|---|
| `lesson` | Something learned that should change future behaviour | Statement, then **Why:** and **How to apply:** |
| `pattern` | A recurring observation, with occurrences | Statement, then the occurrences with dates |
| `rejected` | Something the agent proposed that was turned down | What was proposed, when, and the reason given |
| `reference` | A pointer to something external | What it is and when it is worth reaching for |

**`lesson` carries `Why:` and `How to apply:` because a fact without an application rule is trivia.** The agent does not need to be told what it observed; it needs to know when the observation should alter what it does.

**`rejected` is the type that makes a proactive agent tolerable.** Without it, an agent that fires on a schedule proposes the same idea every run, forever, and gets muted. Recording the rejection *and its reason* lets it distinguish "you said no" from "you said no because it was premature, and circumstances have changed".

Link between facts with `[[other-fact-slug]]`.

## Budget

| | Default | Meaning |
|---|---|---|
| Total | **12,000 characters** across the whole memory directory | Roughly 3,000 tokens — read whole, every run |
| Consolidation threshold | **80%** (9,600 characters) | Above this, consolidating is part of the run |
| Index | 60 lines | |

An agent may declare a different budget in its definition; the default is the one `tools/check` assumes when none is stated.

The budget is a forcing function, not a storage limit. Its purpose is to make the agent choose. Raising it because memory is full is almost always the wrong move — the right move is consolidation, and an agent that genuinely needs more than 12,000 characters is usually two agents.

### Consolidating

When the memory is over threshold, the run includes:

1. **Merge** facts that are variations on one idea into the strongest statement of it.
2. **Delete** facts the world has since contradicted, and `rejected` entries whose reason no longer holds.
3. **Compress** what survives — drop the narrative of how something was discovered and keep the rule.
4. **Rebuild** `MEMORY.md` to match.

Consolidation is destructive and that is intended. Memory that only grows is an archive, and an archive is not read.

## Protocol

### Reading

The first instruction in the agent's definition, before anything else:

1. Read `MEMORY.md`.
2. Open the facts whose hooks are relevant to the task at hand.
3. Do not open all of them by reflex — that is what the hooks are for.

### Writing

Governed by the agent's declared shape, `deliverable` or `caller` ([design.md](design.md)). Whichever applies:

- One fact per file, never an append to a growing log.
- Update `MEMORY.md` in the same run — a fact that is not in the index will not be found.
- When adding a fact that supersedes an existing one, either edit the existing one or mark it `superseded_by`. Do not leave two facts disagreeing: the agent will read both and pick arbitrarily.

### What does not belong in memory

- **Anything the agent can read at run time.** File contents, repository structure, command output. Memory is for what cannot be re-derived.
- **Credentials, tokens, keys.** Memory is replayed verbatim into every future run of that agent.
- **Conversation transcript.** Memory is conclusions, not history.
- **Anything true only of one run.** "The build was broken" is not a fact; "this build breaks whenever X" is.
