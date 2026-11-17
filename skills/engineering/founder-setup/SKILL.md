---
name: founder-setup
description: Set up founderstack for this repo: detect the gate commands, protected branches, production guards, dev URL, where work is logged and who sits on the review council, show the draft, and write .agents/founderstack.md once you approve. Run once per repo, or again when the setup changes.
disable-model-invocation: true
---

# /founder-setup: teach the stack this repo, once

Every founderstack skill is generic. What makes it safe in *your* repo is one
file, `.agents/founderstack.md`. It says which commands prove a change, which
branches are never pushed, what counts as production and where work gets
logged. This skill writes that file from what it detects and what you confirm.
Skills read the file; no skill hardcodes a project.

## When NOT to use this

- The file exists and nothing changed. Skills already read it.
- You want to change one value. Edit the file directly; it is plain Markdown.

## Steps

1. **Explore before asking.** Read the repo; do not guess:
   - gates: `package.json` scripts (`type-check`, `typecheck`, `lint`, `test`,
     `test:run`), `Makefile`, `justfile`, `pyproject.toml`, `Cargo.toml`, and the
     commands CI actually runs (`.github/workflows/*.yml`);
   - protected branches: the default branch (`git symbolic-ref
     refs/remotes/origin/HEAD`), and any branch that CI deploys from;
   - push remote: `git remote -v` (if one remote has its push URL disabled,
     another remote is the push remote);
   - production guards: deploy config (`vercel.json`, `fly.toml`, `railway.*`),
     database scripts that push schema, env files that name a prod host;
   - live drive: the dev command and its port;
   - rules: the hard rules (never, always, must) in `AGENTS.md`, `CLAUDE.md`
     and `CONTRIBUTING.md`.
2. **Draft the file** from [references/config.md](references/config.md). Fill
   in what you detected and mark each detected value with
   `(detected: <where>)`. Where you found nothing, keep the section's
   placeholder; do not invent a value.
3. **Ask one section at a time**, only for the sections that matter: protected
   branches, production guards, worklog target, council seats. Put your
   recommended answer first in each question. "Accept the whole draft" is one
   of the options.
4. **Write `.agents/founderstack.md`** only after the user approves. If the file
   already exists, show the diff before you overwrite it.
5. **Point to it, once.** If `AGENTS.md` or `CLAUDE.md` exists, offer to add one
   line: `founderstack config: .agents/founderstack.md`. Never create an
   instruction file the repo does not already have.
6. **Smoke test.** Run each gate command once and report the result. Keep a gate
   that fails today, and mark it red-on-main.

## Traps

- CI is the truth for gates. A `test` script that CI does not run, or runs with
  different flags, is not the gate. Copy the command CI runs.
- A protected-branch list that says only `main` usually misses release and
  staging branches. Ask the user.
- Never put secrets, connection strings or tokens in the file, because it gets
  committed. Write the guard ("never run `db:push` against prod"), not the URL.

## Reply

The path you wrote, each gate with today's result (green or red), the guards,
the sections you left as placeholders, and Not checked.
