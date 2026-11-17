# founderstack v1: plan

Status: proposed, 2026-11-17. Branch `feat/founderstack-v1`.

![founderstack architecture](assets/diagrams/architecture/01-founderstack.svg)

## Diagnosis

`ritmillio/skills` was a shelf of 13 good, unrelated skills. It had no entry point, no shared rules, no tests and no per-repo config. The three stacks we learned from each solve part of that:

| Stack | What it does best | What it lacks |
|---|---|---|
| [pstack](https://github.com/cursor/plugins/tree/main/pstack) (Lauren Tan) | One router (`poteto-mode`) sends work to 22 playbooks. Principles are indexed with triggers. Work is proven by running it. The author never verifies their own work. | Built for Cursor first. Its model panels collapse outside Cursor. It merges PRs and bans question tools. |
| [tstack](https://github.com/t3dotgg/tstack) (Theo Browne) | Proof plus a merge gate that checks a yes/no fact. Waits on PR events, never on a sleep loop. A council of models from different vendors. PR bodies start with the problem. | No tests, no versions, no planning layer. Auto-merges. |
| [mattpocock/skills](https://github.com/mattpocock/skills) (Matt Pocock) | Splits skills into ones the user starts and ones the model starts. One setup skill writes per-repo config files. Debugging starts with a command that is already red. `.out-of-scope/` keeps the catalogue small. | No CI enforcement. Nothing happens after the PR body. Long runs are only in beta. |

None of them has: unattended multi-hour runs (relay), safety rules for many agents in one checkout, the company side (bills, morning brief, machine health, security), or **measured evidence that a skill helps**.

## Thesis

**One founder, a full team of agents.** Five promises, each one checkable:

1. **Prove it.** Done is a yes/no fact backed by evidence from this session. Every reply says what was NOT checked.
2. **Run without you.** Hours of work with nobody watching. Fresh processes, a committed ledger, a draft PR. The stack never merges and never touches production.
3. **Many agents, one machine.** Worktrees, the branch checked inside every commit command, no stash in a shared tree, cleanup that never loses work.
4. **The company too.** Bills, the morning brief, prod triage, machine health, security.
5. **Measured.** Every skill ships an eval suite that runs with and without the stack (`claude plugin eval`). CI lints every skill.

## Architecture

- **`founder-mode`: the one entry point.** It reads the task, picks a playbook from `playbooks/`, copies its steps into the todo list and runs the skills those steps name. Each playbook has an ownership line, 4-8 steps and a fixed **Reply** contract that requires evidence. If no playbook fits, it designs one for this task and says so.
- **`principles.md`: one file, not 24 skills.** About 15 principles drawn from rulings we already live by. Each has a "when it applies" trigger. When the agent applies one it must name it and the decision it changed. Subagents get the same file through `worker.md`.
- **`founder-setup` writes `.agents/founderstack.md` in the host repo.** It holds: gate commands, protected branches, the push remote, prod guards, the dev URL, the invariants file, where the worklog goes, notification settings, council seats. Skills read this file and never hardcode a project. If it is missing they detect what they can and ask.
- **Invocation split (from Matt).** Skills with side effects or a high token cost (`founder-setup`, `pr-fold`, `collect-bills`, `free-disk`, `memory-hygiene`) are user-invoked only. The rest stay model-invoked, with descriptions that lead with triggers.
- **Neutral capability verbs, one adapter table per harness** (`docs/harness.md`): "ask with options", "spawn a subagent", "watch a background process". Mapped for Claude Code, Codex, Cursor and Gemini CLI. A missing capability is reported, never faked.
- **Hard stops, in every relevant skill:** never merge, never push `main` or other protected branches, never touch production data, ask with selectable options and put the recommendation first, no AI signature on the user's output.

## Catalogue (25 skills)

| Folder | Skills | Source |
|---|---|---|
| `engineering/` | founder-mode, founder-setup, grill, draft-plan, shred-plan, spike, why, verify, council, ship-pr, pr-fold, safe-migration, relay, new-skill | 4 kept, 6 ported and made generic, 4 new |
| `agent-ops/` | telegram-notify, memory-hygiene, worklog, model-router | 2 kept, 2 from open PRs #8 and #10 |
| `company/` | morning-brief, collect-bills, vercel-triage | kept |
| `machine/` | reclaim, free-disk, worktree-janitor, mac-compromise-check | kept |

Ported (all project names, paths and rules move into the config file):

- `verify`: an adversarial loop of gates, review, missing tests and a live drive, ending in SHIP / SHIP WITH NOTES / NOT READY plus a "not verified" list.
- `why`: root cause. Adds Matt's gate (a red command first) and keeps our "name the violated assumption".
- `grill`: an interview over open questions, one at a time, each with a recommended answer.
- `spike`: a time-boxed, throwaway prototype that answers one question.
- `pr-fold` (+ a generic `fold.sh`): folds PR branches into an integration branch, never a protected one.
- `new-skill`: replaces `scaffold-skill` and `scripts/new-skill.sh`. Writes the skill, its eval case, the manifest entries and the README row.

New:

- `council`: cross-vendor review rounds, with stable finding ids, blocker/should/nit defined against the stated intent, and a budget of 3 rounds. Without other vendors it runs fresh subagents with different lenses and says so.
- `ship-pr`: files a PR that leads with the problem, then waits on CI and review bots through an event-driven waiter (our own script), fixes real findings and stops at "ready for you to merge".

## Quality bar (what makes it "the best")

- `scripts/check-skills.mjs`, run in CI on every PR. It checks that:
  - frontmatter is valid and `name` matches the folder;
  - the description is no longer than 1024 characters and leads with a trigger;
  - every skill is listed in `plugin.json`, `marketplace.json` and the README table;
  - relative links resolve;
  - every skill has at least one eval case;
  - scripts pass `bash -n` and shellcheck;
  - an optional private-name denylist (a local file that is never committed) finds nothing.
- `claude plugin validate .` in CI.
- `evals/<skill>-*/`: at least one case per skill. Each case has a trigger indicator (`tool_used: Skill`) and an LLM-graded outcome, with fixtures built by `scaffold_script`. Run by hand or by `workflow_dispatch` with a cost cap. The README publishes the with/without scores we measured, and never a number we did not measure.
- `docs/harness.md` (portability), `.out-of-scope/` (rejected ideas, starting with auto-merge), a "Learned from" README section near the top plus `CREDITS.md` that maps each borrowed idea to its source file. Per-skill `metadata.credits` where an idea came from elsewhere. We copy ideas, not text, so no third-party licence notice is needed. If any text is copied later, its MIT notice goes into `THIRD_PARTY_NOTICES`.
- `scripts/link-skills.sh`: relinks local installs after the folder move. Today `~/.agents/skills/*` are symlinks into `~/Developer/skills` and `~/Developer/skills-founder-batch`.

## Out of scope for v1

Auto-merge (never). Cursor-only features. A Notion clone. Rewriting relay internals (the uncommitted relay fixes on `fix/relay-host-runner` stay in their own lane). Matt's skills stay a passthrough (we do not copy them).

## Workstreams, each with its check

| # | Work | Check |
|---|---|---|
| 0 | Fold open PRs #9, #8, #10 as separate commits | `git log` shows 3 cherry-picks; no conflict markers |
| 1 | Rename strings (`ritmillio-tools` → `founderstack`), new folders, root `plugin.json` with a `skills` array, marketplace with the bundle plus per-skill entries | `claude plugin validate .` green; `npx skills add ./ --list` lists all 25 |
| 2 | `check-skills.mjs` + GitHub Actions workflow | lint green on the branch; a deliberately broken fixture fails it |
| 3 | `founder-mode` + `principles.md` + playbooks + `worker.md` + `founder-setup` + the config spec | every skill a playbook names exists (lint); a dry-run setup writes a valid config in a scratch repo |
| 4 | Port verify, why, grill, spike, pr-fold, new-skill | grep finds no private names; each one runs once on a scratch repo |
| 5 | council, ship-pr + waiter script | the waiter runs `--help` and one real read-only poll on a public PR |
| 6 | Evals for all 25 skills | `claude plugin eval . --runs 1` completes; scores recorded in the README |
| 7 | README, CREDITS, harness doc, diagram, CHANGELOG with migration notes | links lint green; diagram reviewed by eye |
| 8 | Draft PR, Notion record (pending until the connector is signed in again) | PR open, CI green |

## Open questions

- The eval spend cap for the first full run (25 skills × 1 run × 2 arms = 50 agent runs).
- Close #8, #9 and #10 after the fold, or keep them open until v1 merges.
