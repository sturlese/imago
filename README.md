# Imago

**A template for building local Claude Code agents that remember who they are. Persistent memory, functional personality, zero infrastructure.**

![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg) ![Claude Code](https://img.shields.io/badge/Claude_Code-native_subagents-8B5CF6) ![Python](https://img.shields.io/badge/Python-3.10%2B_stdlib_only-3776AB) ![Dependencies](https://img.shields.io/badge/dependencies-zero-brightgreen)

A Claude Code subagent is powerful and amnesiac. It reads your files, runs your tools, returns an answer — and forgets everything. Spawn it again tomorrow and it starts from nothing, re-learning what it worked out yesterday, repeating the suggestion you already rejected.

Imago gives an agent the two things that turn it from a function call into a colleague: **a memory that survives sessions**, and **a personality that changes what it produces**. Both are plain markdown files. There is no runtime, no daemon, no database — the agents are native Claude Code subagents, and Imago is the convention that makes them persistent.

It is small on purpose. The fastest way to understand how agent memory actually works is to build one where every moving part is a file you can open, and the hard part turns out not to be storage at all. If you want capability out of the box instead, [there are frameworks for that](#scope--and-when-you-want-something-heavier) and this README says which.

> ### This is a template, not a library
>
> **Your agents never live in this repo.** They are generated into `~/.claude/`, where Claude Code reads them. This repo only ever contains templates, docs, tools, and one worked example.
>
> Use **"Use this template"** on GitHub rather than `git clone` — you get a repo with no shared history and no upstream remote, so your own agents can never end up in a pull request here by accident.

Named after the *imago*: in entomology, the final mature form an insect becomes after all its molts — not a stage, a destination. In Jungian psychology, the persistent internal image of another person that governs how you relate to them. Both are the point: agents that mature into a stable identity instead of resetting, carrying a representation durable enough to have a character.

Two sources shaped this:

- **[Allie K. Miller on The Startup Ideas Podcast](https://www.youtube.com/watch?v=EzQAgnjTq2k)** (with Greg Isenberg, Aug 2026) — the case for an agent *workforce*: a fleet with named roles, personalities that are functional rather than decorative, and roles nobody would ever hire a human for because at the margin an agent costs nothing.
- **[Hermes Agent](https://github.com/NousResearch/hermes-agent)** (Nous Research) — the memory contract: bounded local files, a tight budget as a deliberate forcing function for curation, and consolidation when the budget fills. The podcast is not explicit about how memory actually works; Hermes is.

> ### "Think of the factory behind the one singular task instead of the one singular task itself."
>
> — Allie K. Miller, on what she calls one of the biggest ways to rethink work in the AI age

That line is why this repo is a template and not a fleet. The obvious move is to build the agent you need today. The move that compounds is to build the thing that produces agents — so the second one costs an afternoon instead of a month, and the twentieth costs ten minutes. Your agents are the product. This repo is the factory.

---

## Philosophy

Most agent-memory tooling reaches for retrieval infrastructure: vector databases, embedding pipelines, temporal knowledge graphs, hosted memory services. Imago bets the other way — **for a handful of agents holding a few dozen facts each, a directory of markdown and `grep` is not a compromise, it is the correct answer**:

- **No vector DB, no embeddings, no index.** An agent's memory is small by design, because a tight budget is what forces it to curate. Nothing here needs to be searched; it needs to be *read*, whole, at the start of every session.
- **No runtime.** Imago generates the `.md` files Claude Code already reads. Delete Imago and your agents keep working.
- **No scheduler.** Proactivity matters — it is most of the point — but the plumbing is already native. Imago documents the contract an agent must satisfy to run unattended and leaves the cron to `/schedule`.
- **Personality is functional or it is decoration.** "You are a quirky assistant" changes nothing. A personality is only worth writing down if it changes what the agent *notices*, what it *reports*, and above all what it *refuses to do*.
- **The write path is enforced, not requested.** The hard problem in agent memory is not storage, it is that agents reliably read their memory and unreliably write it. Imago's templates make the write structurally unavoidable rather than politely instructed. This is the design's centre — [the full argument is here](docs/design.md).

## Scope — and when you want something heavier

Be clear about what this is. **Imago is a deliberately basic setup for learning how agents are actually built and how their memory works.** It is a convention over Claude Code's native subagents: a few markdown templates, two scripts, and an argument about the write path. You can read the whole thing in an afternoon and you will understand every file in it. That is the point — the mechanism is the deliverable, not a feature list.

If what you want is capability out of the box rather than understanding, two open-source frameworks already solve that and solve it well:

- **[OpenClaw](https://github.com/openclaw/openclaw)** — a full agent runtime rather than a framework you assemble. Agents that run 24/7 across 20+ messaging platforms, 100+ built-in skills with a [ClawHub](https://clawhub.ai) registry and one-command install, 1,000+ external tool integrations, any MCP server available without writing a wrapper, browser automation, scheduling, voice, and multi-agent coordination. If your problem is coordination and breadth, start here.
- **[Hermes Agent](https://github.com/NousResearch/hermes-agent)** — a single self-improving agent with 40+ built-in tools: web search, browser automation, visual understanding, code execution, subagent delegation, planning, scheduled tasks, and a memory system with eight pluggable providers. If your problem is always-on automation that learns your preferences over time, start here.

Reach for one of those if you want batteries included, always-on multi-platform operation, or a marketplace of skills you did not have to write. Reach for Imago if you already live in Claude Code, want two to five agents rather than a platform, and would rather own five files than adopt a runtime.

The two are not alternatives so much as different rungs. Imago's memory contract is [borrowed from Hermes](docs/design.md) — bounded files, budget as a forcing function, consolidation on fill — so the mental model transfers directly. Outgrowing this repo means moving to a framework whose memory model you already understand, which is a better outcome than never having understood it.

## The three axes

An agent is three orthogonal things. Conflating them is the design error Imago is shaped to prevent:

| | What it is | Where it lives | Nature |
|---|---|---|---|
| **Personality** | who the agent is | the body of its definition | per-agent, static |
| **Memory** | what it has learned | `~/.imago/<name>/` | per-agent, **stateful** |
| **Skills** | what it can do | `~/.claude/skills/` | **shared**, stateless |

Skills are identical for everyone who loads them. Memory is private and accumulates. Imago ships no skills at all — they are already a solved, documented Claude Code feature. Imago's contribution is the other two axes.

## Where things live

| | `imago/` (this repo) | `~/.claude/agents/` | `~/.imago/` |
|---|---|---|---|
| Contains | templates, docs, tools, one example | your agent definitions | your agents' memories |
| Written by | pull requests to the template | `tools/new-agent` | the agents themselves |
| Owned by | the template | Claude Code | your fleet |
| Public? | yes | your call, in a separate repo | your call |
| Contains anything of yours? | **never** | everything | everything |

`tools/new-agent` refuses to write inside this repo. If you point it here, it errors and tells you where agents actually go.

Definitions and memories live in **separate trees** deliberately. Definitions have to be in `~/.claude/agents/` because that is where Claude Code looks. Memory is elsewhere because an agent can only write where it has been granted, and granting `~/.claude` would hand it its own configuration, every other agent's definition, and your settings. `~/.imago` is the narrow grant.

## Quick start

**Requirements:** [Claude Code](https://claude.com/claude-code) · Python 3.10+ · git

Install the worked example and watch memory survive a session boundary. Two minutes:

```bash
# 1. Get the template — "Use this template" on GitHub, or:
git clone https://github.com/sturlese/imago && cd imago

# 2. Install the example agent
tools/new-agent --from-example toby

# 3. Open a session that *is* Toby, and talk to him
cd ~/some/project
claude --agent toby --add-dir ~/.imago
```

You are now in a conversation with Toby rather than with Claude Code. Ask him to review the project, push back on what he found, ask for more detail — it is an ordinary interactive session, except the persona, the mandate and the memory are his. Approve the writes when prompted; that is him recording what he found.

**Then quit, and start him again** — a completely separate session, sharing nothing but a directory:

```bash
claude --agent toby --add-dir ~/.imago
```

Ask him what he already knows about the project. He will tell you, from a file he wrote in a session that no longer exists.

**Then ask him to review it again.** This is the test that matters. A memory you can read back only proves a file survived; what you want is a memory that changes what the agent *does*. Watch for:

- he re-checks the findings he already holds **before** looking for anything new, because one of his own facts told him to;
- he adds an occurrence to an existing fact instead of filing the same finding twice;
- he files only what is genuinely new;
- he declines to file something that fails his own bar, and says so.

That is the whole thesis. Everything else in this repo is in service of making it reliable.

Check the fleet at any time:

```bash
tools/check
```

### The same agent, three ways to run it

| | Command | Use it for |
|---|---|---|
| **Interactive, as the agent** | `claude --agent toby --add-dir ~/.imago` | Working *with* the agent — back and forth, as long as you like. The session is Toby |
| **Non-interactive, as the agent** | `echo "..." \| claude -p --agent toby --allowedTools Write Edit --add-dir ~/.imago` | Cron, CI, anything scheduled. One shot, prints, exits |
| **As a subagent** | Open `claude`, then: *"use the toby agent to review this"* | A quick delegated errand inside work you are already doing |

The first two are the agent; the third is an errand the orchestrator runs. Only the first two get session hooks, and only the second can be scheduled.

Worth an alias for an agent you use often:

```bash
alias toby='claude --agent toby --add-dir ~/.imago'
```

> **In the `-p` form the two flags are not optional.** Writes outside the working directory are denied by default, and under `-p` there is nobody to approve them — so without `--add-dir ~/.imago --allowedTools Write Edit` the agent runs, reports, and records nothing. The prompt also has to go through **stdin**, because both flags are variadic and would otherwise swallow a trailing prompt argument. This is the most common way an Imago agent silently accomplishes nothing — [full explanation](docs/proactivity.md).

## Creating your own agent

```bash
tools/new-agent phoebe --memory deliverable
```

This scaffolds `~/.claude/agents/phoebe.md` from [`templates/agent.md`](templates/agent.md), an empty memory at `~/.imago/phoebe/`, and prints the command to run it. Then you write the personality — the tool deliberately does not generate it, because a personality assembled from filled-in slots is exactly the decoration this repo argues against.

### Personality, in four fields

The template asks for four things. Vagueness in any of them produces an agent that sounds distinctive and behaves generically:

| Field | The question it answers | Example (Phoebe, a 10× interrogator) |
|---|---|---|
| **Disposition** | What is it inclined to notice? | Gaps between what was built and what was possible |
| **Voice** | How does it report? | Provocative; asks rather than asserts |
| **Refusals** | What does it decline to do, in character? | **Never approves anything.** Cannot say "looks good" |
| **Bar** | What does "good" mean to it? | A 10× answer, or the question stands |

**Refusals are the field that matters and the one people skip.** A personality without a *no* is a costume. An agent whose job is to demand ambition must be forbidden from approving, or it drifts into another voice telling you nice work. Toby's refusal is that he never proposes fixes — he only reports — which is what keeps his output trustworthy and his scope small.

### Memory, in one of two shapes

Every agent with memory declares how the write happens. There is no third option, and in particular there is no "do your job and also update your memory at the end" — that is the shape that silently loses everything:

- **`deliverable`** — the memory file *is* the output. No file, no completed task. Zero discretion, and the shape to prefer.
- **`caller`** — the agent returns its findings and something else persists them. The agent still decides *what* is worth remembering; only the writing moves out.

`tools/new-agent` will not generate an agent without one of these.

### Running unattended

An agent that only runs when you invoke it barely needs memory — you would remember what it told you. Memory pays off when the agent fires on a schedule and accumulates across runs you never watched. That is also where the write path gets dangerous, because nobody is there to notice a skipped one.

Agents intended to run unattended declare it in an `## Operating mode` section, which is both the declaration and the instruction the model reads. The requirements are stricter than for interactive agents — [see the checklist](docs/proactivity.md).

## Reference

| Document | What is in it |
|---|---|
| [docs/design.md](docs/design.md) | Why agents read memory reliably and write it unreliably, and the two shapes that fix it |
| [docs/memory-spec.md](docs/memory-spec.md) | The memory contract: layout, fact types, budget, consolidation |
| [docs/proactivity.md](docs/proactivity.md) | What changes when an agent runs with nobody watching |
| [templates/agent.md](templates/agent.md) | The agent skeleton |
| [examples/toby.md](examples/toby.md) | A complete worked agent, commented |

## Contributing

Improvements to the templates, tools and docs are welcome. Pull requests should only ever touch `templates/`, `tools/`, `docs/`, `examples/` and the top-level docs — anything outside that is local work that has followed you in. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT — see [LICENSE](LICENSE).
