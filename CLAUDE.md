# Imago — working on the template

This repo is a **template** for building Claude Code agents with persistent
memory and functional personality. It is not a library and it has no runtime.

## The hard rule

**No agent and no memory ever lives in this repo.** Agents are generated into
`~/.claude/agents/`, memories into `~/.claude/memory/`. `agents/` and `memory/`
are in `.gitignore` as a defensive measure and `tools/new-agent` refuses to write
anywhere under this directory.

If a session here produces an actual agent for the user, it goes to `~/.claude/`,
never into a directory in this checkout — and the example in `examples/` stays
generic, with nothing specific to the user's projects, employer or clients.

## Layout

```
docs/design.md         why the write path is the hard problem — the repo's thesis
docs/memory-spec.md    normative memory contract; what tools/check verifies
docs/proactivity.md    what changes when an agent runs unattended
templates/             agent.md, fact.md, MEMORY.md — scaffolding sources
examples/toby.md       one complete worked agent, deliberately generic
tools/new-agent        scaffolds into ~/.claude/; refuses to write in the repo
tools/check            verifies an installed fleet against the spec
```

## The thesis, so changes stay coherent

Agents read their memory reliably and write it unreliably, because reading is
enforced by output quality and writing is enforced by nothing. Everything here
follows from that:

- Memory shape is `deliverable` or `caller`, never "update your memory at the
  end". `new-agent` refuses to scaffold without one.
- Memory is bounded (12,000 chars, consolidate at 80%) because the budget is what
  forces curation, not because storage is scarce.
- Personality is four fields — disposition, voice, refusals, bar — and
  **refusals** is the load-bearing one. A personality without a `no` is a costume.
- Skills are shared and stateless; memory is private and stateful. Imago ships no
  skills.

Two named inspirations, both public and both cited in the docs: the Allie K.
Miller / Greg Isenberg podcast episode (the fleet, functional personalities) and
Nous Research's Hermes Agent (bounded memory files, budget as forcing function,
consolidation). Keep the genealogy to those two — do not import reasoning from
other projects into this repo's rationale.

## Conventions

- **Language**: everything in the repo is written in English.
- **Python**: 3.10+, standard library only. No dependencies, ever.
- **Tools are executables**, not modules: `tools/new-agent`, no `.py` extension,
  shebang, `chmod +x`.
- **Docs say why.** The mechanics are short; the reasoning is the value.
- **No status tables.** Plain prose and plain lists.

## Non-goals

Declining these is a feature, and each one is argued in `docs/design.md`: no
scheduler (native `/schedule` covers it), no retrieval layer, no vector store, no
skills, no locking, no coordinator agent, no dependencies.

Before adding anything, check it against that list.

## Verifying a change

```bash
tools/new-agent scratch --memory deliverable --dir /tmp/imago-test
tools/check --dir /tmp/imago-test
```

The real test is the README quick start: install the example agent, run it, start
a fresh session, confirm it remembers. That round-trip is the whole claim.
