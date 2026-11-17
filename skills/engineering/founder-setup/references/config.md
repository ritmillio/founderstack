# `.agents/founderstack.md` template

Plain Markdown, committed with the repo. Skills read the section they need and
fall back to detection when a section is missing. Keep it short. No secrets.

```markdown
# founderstack config

## Gates
Commands that must pass before anything is called done. Copy what CI runs.
- typecheck: `pnpm run type-check`
- test: `pnpm run test`
- lint: `pnpm run lint`
- extra: `pnpm db:check-migrations` (only when migrations change)

## Protected
- branches: main, staging        # never commit to, never push
- push remote: origin            # the remote that accepts pushes
- pull requests: draft first, never merge

## Production guard
Things no agent runs or touches. Name the action, never the secret.
- never: `pnpm db:push` against a shared database
- never: delete or overwrite environment variables on shared environments
- prod data: read-only, and only through <the documented read-only path>

## Live drive
- start: `pnpm dev`
- url: http://localhost:3000
- check: light and dark theme, phone width

## Invariants
Repo rules every review checks. Link the file that owns them, or list them.
- see AGENTS.md, section "Non-negotiable"

## Worklog
- target: notion | markdown:docs/worklog.md | none
- notion config: .agents/notion-worklog.json   # only for target notion

## Notify
- telegram: off                  # on = telegram-notify is set up on this machine

## Council
Review seats, one model per vendor. Empty = fresh same-model reviewers with different lenses.
- seats: <model A>, <model B>, <model C>
- rounds: 3 (5 for security or data changes)

## Models
Overrides for model-router (optional).
- default: <model>, effort high
```

Sections a skill reads:

| Skill | Sections |
|---|---|
| founder-mode | all, as context |
| verify | Gates, Live drive, Invariants, Production guard |
| why | Gates, Production guard |
| ship-pr | Gates, Protected |
| pr-fold | Gates, Protected |
| council | Council, Invariants |
| spike | Live drive, Production guard |
| relay | Gates, Protected, Production guard, Notify |
| notion-worklog | Worklog |
| model-router | Models |
| safe-migration | Gates, Production guard |
