# Contributing

Improvements to the templates, tools and docs are welcome.

## Pull requests only touch the template

```
docs/  templates/  examples/  tools/  README.md  CONTRIBUTING.md  CLAUDE.md  LICENSE
```

Anything outside that list is local work that has followed you in. In particular
**`agents/` and `memory/` must never appear in a pull request** — those are your
own agents and their memories, they belong in `~/.claude/`, and they are in
`.gitignore` precisely so a stray one cannot be committed by accident.

If you are working from a clone rather than "Use this template", check
`git status` before you push.

## What makes a good change

The repo has a thesis: agents read their memory reliably and write it
unreliably, so the write path has to be enforced structurally rather than
requested politely. Changes that strengthen that hold up well. Changes that add
a runtime, a scheduler, a retrieval layer or a dependency work against it — see
the non-goals in [docs/design.md](docs/design.md) before proposing one.

Concretely:

- **Templates** — an addition earns its place if it changes agent behaviour. A
  field nobody fills in is worse than no field.
- **Tools** — Python 3.10+, standard library only. `check` should verify things
  the specification states; if a rule cannot be checked mechanically it probably
  belongs in the docs as guidance rather than in the linter as a warning.
- **Docs** — say why, not just what. The reasoning is the part of this repo
  worth reading.
- **Examples** — must be genuinely generic. An example that needs the reader to
  know about your projects is not an example.

## Testing a change

There is no test suite. Scaffold into a scratch directory and check it:

```bash
tools/new-agent scratch-agent --memory deliverable --dir /tmp/imago-test
tools/check --dir /tmp/imago-test
```

`--dir` exists for this. Note that `new-agent` refuses to write anywhere inside
the repo, so a scratch fleet has to live outside it.

Before opening a pull request, confirm the quick start in the README still works
end to end — install the example, run it, and verify memory survives a session
boundary. That round-trip is what the repo claims; a change that breaks it is
not a change worth having.
