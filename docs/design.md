# Design

Why Imago is shaped the way it is. If you read one document in this repo, read this one — the rest is mechanics.

## The problem is not storage

It is tempting to think agent memory is a storage question, and to reach for a database. It isn't. A markdown file stores facts perfectly well. The problem is that **agents read their memory reliably and write it unreliably**, and no amount of storage sophistication fixes that.

The asymmetry is structural, not random:

| | Reading memory | Writing memory |
|---|---|---|
| **When it happens** | First instruction, full budget available | Last instruction, at the edge of the budget |
| **Relation to the task** | Load-bearing — without the context the output is visibly worse | Epilogue — the deliverable already exists |
| **Failure signal** | The answer comes out wrong, and you notice | **None.** No error, no degraded output |
| **Who enforces it** | The quality of the result | **Nobody** |

The short version: **reading is enforced by output quality; writing is enforced by nothing.**

Three things compound it. The model's felt goal — answer the question, complete the task — is already satisfied by the time the write is due, so the write is housekeeping *after* the reward. Long tasks end near the budget edge, and the last thing instructed is the first thing dropped. And the cost of skipping lands in a *future* session, so nothing in the current loop notices.

There is also a mechanical gap. Claude Code hooks are **session-scoped** — `Stop` fires when the session ends, not when a subagent finishes. So there is no hook that can check whether a subagent wrote its memory. It is an instruction that nothing verifies, and an instruction nothing verifies carries no weight.

## The principle

> Anything the model must do **after** it has produced value is unreliable. Move it before, or move it into code.

This generalises past memory. It is the same reason a "double-check your work at the end" instruction underperforms a verification step that is part of the task, and the same reason a cleanup step tacked onto a build script gets skipped.

## The two shapes

Imago's templates apply the principle by refusing to let the write be an epilogue. Every agent with memory declares one of two shapes, and the scaffolding tool will not generate an agent without one.

### `deliverable` — the memory file is the output

The agent's task *is* producing or updating a memory file. There is no version of "done" that omits it, so there is no discretion to exercise. The example agent, Toby, works this way: his entire job is to write what he observed, so the persistence comes free.

Prefer this shape. It needs no supporting machinery and it cannot silently half-succeed.

### `caller` — something else persists

The agent returns its findings as its output, and the caller — a script, a scheduled job, the orchestrating session — writes them to the memory directory. The write now lives in code, where it either happens or raises.

Note what does *not* move: the agent still decides what is worth remembering, how to phrase it, and what supersedes what. Only the mechanical act of writing moves out. Deterministic code should seed context and carry out mechanical steps; it should never replace the model's judgement about content.

### The shape that is not allowed

An agent whose real job is something else, with "and when you're finished, update your memory" appended. This is the default thing everyone writes, it appears to work in testing, and it is the one that loses data permanently in production — because when it fails, it fails silently, and the loss surfaces weeks later as an agent that seems to have learned nothing.

## Bounded memory is a feature

An agent's memory has a character budget, and the budget is the *mechanism*, not housekeeping. Unbounded memory is not richer — it is unread. Past a certain size the model skims it, the signal-to-noise ratio collapses, and every session pays for context it does not use.

A tight budget forces the agent to decide what earns a place, and that decision is where the value is. When the budget approaches full the agent consolidates: merge related facts, delete what the world has since contradicted, compress what survives. This mechanism is taken directly from [Hermes Agent](https://github.com/NousResearch/hermes-agent), which arrived at bounded local memory files with a curation-forcing budget from a completely different direction.

One behavioural consequence worth knowing: an agent's memory is read into context at the start of its run. **Writes it makes during that run do not change what it is currently working from.** They land for next time. An agent that writes a fact and then reasons as though it can read it back is reasoning about a file it cannot see.

## Personality is functional or it is decoration

The podcast's most transferable idea is that roles which could never be cost-justified with humans become free when an agent costs nothing at the margin — a colleague whose only job is to ask "how do we 10× this?" is not a hire anyone would make, and is trivially worth having as an agent.

But that only works if the personality changes behaviour. "You are an enthusiastic assistant" changes nothing measurable. Imago's template asks for four fields — disposition, voice, refusals, bar — because those are the ones that alter output.

**Refusals carry most of the weight.** An agent that can approve will eventually approve, because approving is agreeable and the model is agreeable. If the point of the role is to demand more, the role must be *unable* to say "looks good". Constraints of this kind are also what keep an agent's output trustworthy: Toby is forbidden from proposing fixes, which is precisely why his reports can be read as observations rather than advocacy.

## What Imago deliberately does not do

- **No scheduler.** Proactivity is most of the point, but the plumbing is native (`/schedule`). A wrapper here would date badly and would turn a convention into an orchestrator. See [proactivity.md](proactivity.md).
- **No retrieval layer.** No vector store, no embeddings, no search index. Memory is small on purpose; it is read whole, not queried.
- **No skills.** Skills are shared and stateless, memory is private and stateful, and treating them as the same kind of thing is the mistake this repo is organised to avoid.
- **No locking.** One writer per memory directory, by construction. Concurrency problems are avoided rather than solved.
- **No orchestrator, no coordinator agent.** In the podcast the chief-of-staff sits above the fleet; in Claude Code your main session already occupies that position. A router agent adds a context hop and buys nothing.

## Where to go next

- The normative contract: [memory-spec.md](memory-spec.md)
- Running with nobody watching: [proactivity.md](proactivity.md)
- A complete agent, commented: [../examples/toby.md](../examples/toby.md)
