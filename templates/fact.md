---
name: {{SLUG}}
description: One line. This is what goes in the MEMORY.md hook, so it has to be enough to rule the fact in or out without opening it.
type: lesson
created: {{DATE}}
---

<The fact itself, stated as a durable claim rather than a report of an event.
"This build breaks whenever X" is a fact. "The build was broken" is not.>

**Why:** <What makes it true, or the evidence. Without this the fact cannot be
re-evaluated later when circumstances change — it can only be obeyed or ignored.>

**How to apply:** <When this should alter behaviour, concretely. A fact without
an application rule is trivia. This field is what earns the fact its place in a
bounded memory.>

<!--
type: one of
  lesson    — something learned that should change future behaviour (Why + How to apply)
  pattern   — a recurring observation; list the occurrences with dates
  rejected  — something proposed and turned down; record WHEN and the REASON given
  reference — a pointer to something external; what it is and when to reach for it

Add `superseded_by: <slug>` when a newer fact replaces this one but keeping the
old one is still useful. Never leave two facts disagreeing without it.

Link to other facts with [[their-slug]].

Never put credentials, tokens or keys in a fact: memory is replayed verbatim into
every future run of this agent.
-->
