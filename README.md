# founderstack

**One founder, a full team of agents.**

Skills for the engineering (plan it, prove it, ship it, run it for hours
with nobody watching) and for the company around it (bills, the morning
brief, prod triage, machine health, security). Written once as `SKILL.md`,
so they work in Claude Code, Codex, Cursor, Gemini CLI and any agent that
reads the open standard.

## Learned from

founderstack exists because three people published how they work. We studied
their stacks closely, took the ideas that held up in our own daily use, and
wrote our own versions. Go read theirs. Each one is excellent at something
this stack is not.

| | What we learned from it |
|---|---|
| **[pstack](https://github.com/cursor/plugins/tree/main/pstack)** by Lauren Tan ([@poteto](https://x.com/poteto)) | One router in front of everything. `poteto-mode` sends a task to one of 22 playbooks, each ending in a fixed reply contract. Principles are short, indexed by when they apply, and cited with the decision they changed. The author never verifies their own work. **Here:** `founder-mode`, its playbooks, `principles.md`, `worker.md`. |
| **[tstack](https://github.com/t3dotgg/tstack)** by Theo Browne ([@t3dotgg](https://github.com/t3dotgg)) | "Done" is a yes/no gate checked on the latest commit. Wait on PR events, never on a sleep loop. Get reviews from models of different vendors and loop until they agree, with a budget that is not approval. PR bodies start with the problem. **Here:** `ship-pr` and its waiter, `council`. |
| **[mattpocock/skills](https://github.com/mattpocock/skills)** by Matt Pocock ([@mattpocock](https://github.com/mattpocock)) | Small, composable skills. One setup skill writes per-repo config, so skills stay generic. Debugging starts with a command that is already red. Grilling goes one question at a time with a recommended answer. Rejected ideas get written down so the catalogue stays small. **Here:** `founder-setup`, `why`, `grill`, [`.out-of-scope/`](.out-of-scope). |

What we copied is ideas, not text. [CREDITS.md](CREDITS.md) maps each borrowed
idea to the file it came from and the file it became. Matt's pack is also
installable straight from his repo through our marketplace (see Install).

## What it promises

1. **Prove it.** Done is a check that ran in this session and passed. Every
   reply ends with what was *not* checked.
2. **Run without you.** Hours of work with nobody watching: fresh processes, a
   committed ledger, a draft PR. No context rot.
3. **Many agents, one machine.** Worktrees, the branch checked inside every
   commit command, no `git stash` in a shared tree, cleanup that never loses
   work.
4. **The company too.** Invoices, the morning brief, prod logs, a pinned CPU, a
   full disk, a suspicious sign-in.
5. **Measured.** Every skill ships an eval that runs with and without the stack.
   CI lints every skill on every PR.

And it never merges a PR, never pushes a protected branch, never touches
production data, and asks you with options, recommendation first.

![founderstack: one entry, playbooks, skills, proof](docs/assets/diagrams/architecture/01-founderstack.svg)

## Install

Claude Code, the whole stack:

```
/plugin install founderstack --marketplace ritmillio/founderstack
```

Any agent, through the community [`skills`](https://www.npmjs.com/package/skills) CLI:

```bash
npx skills@latest add ritmillio/founderstack            # pick skills interactively
npx skills@latest add ritmillio/founderstack --all      # every skill, every agent
npx skills@latest add ritmillio/founderstack --skill relay
```

Plugin skills are namespaced in Claude Code (`/founderstack:founder-mode`);
CLI-installed skills keep the plain name (`/founder-mode`). Details, per-skill
plugins and Matt Pocock's pack: [INSTALLATION.md](INSTALLATION.md).

## Start

1. `/founder-setup` once per repo. It detects your gate commands, protected
   branches and production guards, shows the draft, and writes
   `.agents/founderstack.md` after you approve.
2. `/founder-mode <the task>` whenever the work needs rigor. It picks the
   playbook and runs the skills for you. `/founder-mode help` tells you which
   skill fits without starting anything.

Every skill also works on its own, and triggers from plain requests ("why is
checkout broken", "ship it", "my disk is full").

## The skills

### Engineering

| Skill | What it does |
|---|---|
| [`founder-mode`](skills/engineering/founder-mode) | The entry point. Picks one of 16 playbooks (bug fix, feature, plan, unattended run, shipping, release fold, migration, prod triage, review, ...), runs the skills it names, applies the principles, and ends with evidence and a Not checked line. |
| [`founder-setup`](skills/engineering/founder-setup) | Teaches the stack your repo once: gates (copied from what CI runs), protected branches, production guards, dev URL, worklog target, council seats. Writes `.agents/founderstack.md` after you approve. |
| [`grill`](skills/engineering/grill) | Pressure-tests a plan before code: one question at a time, each with a recommended answer, biggest unknown first, until every decision is settled or parked. |
| [`draft-plan`](skills/engineering/draft-plan) | Turns an investigation into a plan doc: verified diagnosis, explicit in/out scope, workstreams with proofs of done, sequencing gates, open questions. |
| [`shred-plan`](skills/engineering/shred-plan) | The adversarial pass between "here's the plan" and "let's build it". Verifies every codebase claim with evidence, then hunts hidden dependencies, missing failure modes, scope leaks and done-criteria nobody can check. |
| [`spike`](skills/engineering/spike) | A throwaway prototype that answers one question inside a time budget: variants side by side, you pick, it gets deleted. |
| [`why`](skills/engineering/why) | Root cause, not a plausible cause: one red command first, one hypothesis at a time, the violated assumption named, a fix at the cause, the red command kept as the guard. |
| [`verify`](skills/engineering/verify) | Proves a finished change: gates, a hostile read of the diff, the missing edge-case tests, a live drive of the app, looped until a pass finds nothing new. A fresh agent gives the verdict. |
| [`council`](skills/engineering/council) | Reviews from models of different vendors, in rounds: stable finding ids, blocker/should/nit judged against intent, a budget that is not approval. Says plainly when it is single-vendor. |
| [`ship-pr`](skills/engineering/ship-pr) | Finished branch to "ready for you to merge": a PR that leads with the problem, an event-driven waiter for CI and review bots, real findings fixed, the rest answered. Never merges. |
| [`pr-fold`](skills/engineering/pr-fold) | Folds several PRs into a release branch: dry run for conflicts and migration prefix collisions, a detached worktree, both sides' intent kept, one seams commit. Never a protected branch. |
| [`safe-migration`](skills/engineering/safe-migration) | The boring, safe Drizzle migration ritual. Reads the repo's own rule first, takes the next prefix from disk *and* the default branch, greps for silent `DROP`s, lands schema and migration in one commit. |
| [`relay`](skills/engineering/relay) | Unattended work for a stated duration (4 hours or 24) or until checks pass, on its own worktree and draft PR. Each leg is a fresh process handing a committed ledger to the next, so nothing lives long enough to rot. |
| [`new-skill`](skills/engineering/new-skill) | Turns a workflow you keep re-explaining into a skill, with its first eval case and every registration it needs. |

### Agent ops

| Skill | What it does |
|---|---|
| [`telegram-notify`](skills/agent-ops/telegram-notify) | Telegram pings when an agent finishes, gets stuck on a permission, lands a commit, or a relay run starts, lands, halts or ends. Ships the sender and walks through BotFather and hook wiring. |
| [`notion-worklog`](skills/agent-ops/notion-worklog) | Nothing is done until it is recorded. Every task, QA pass, plan, ruling or incident becomes the right Notion record with a dated work-log entry. Without a connector it writes a `## Notion (pending)` entry instead of pretending. |
| [`memory-hygiene`](skills/agent-ops/memory-hygiene) | Claude Code loads only the head of `MEMORY.md`. Shows how much never reaches the agent (usually the rules), archives finished project memories and moves rules to the top. |
| [`model-router`](skills/agent-ops/model-router) | Picks the cheapest model and effort that can do the job before spending a token: a 3-call probe, a five-axis score, a one-line route card for the session and each subagent. |

### Company

| Skill | What it does |
|---|---|
| [`morning-brief`](skills/company/morning-brief) | A founder's start of day on one screen: repos and PRs, an opt-in business block (inbox, Stripe, signups, prod errors, overdue tasks), your own feeds, and a Top 3 for today. |
| [`collect-bills`](skills/company/collect-bills) | Sweeps your mailboxes for this period's invoices, drops anything without your tax number, downloads only what the archive is missing, checks each is a real PDF, and stages them for the accountant. |
| [`vercel-triage`](skills/company/vercel-triage) | Turns a raw `vercel logs` dump into a triage: de-duplicated, grouped by status and path, 5xx first. Read-only. |

### Machine

| Skill | What it does |
|---|---|
| [`reclaim`](skills/machine/reclaim) | Gives a pinned dev machine back. Reads the system-versus-user CPU split first, because the process at the top is usually a symptom. Reaps stale build watchers, caps the test runner, and says when only a reboot will do. |
| [`free-disk`](skills/machine/free-disk) | The disk fills with build output, not code. Deletes only what rebuilds itself, skips any checkout with a live dev server, and leaves deleting checkouts to `worktree-janitor`. |
| [`worktree-janitor`](skills/machine/worktree-janitor) | Eighty agent worktrees, one table: uncommitted, unpushed, PR state, the dev server holding a port, and a SAFE / ASK / KEEP verdict. Removes only what you pick, after re-checking each. |
| [`mac-compromise-check`](skills/machine/mac-compromise-check) | A read-only triage for "is my Mac hacked": accounts, remote access, listening ports, persistence, extensions, profiles, FileVault, SIP and Gatekeeper. |

## Measured

Every skill has an eval case in [`evals/`](evals): a request phrased the way a
user would say it (never naming the skill), graded PASS or FAIL on the
outcome. `claude plugin eval` runs each case twice, once with founderstack
loaded and once without, so the difference is what the stack contributes.

**Latest run (2026-11-17, Claude Code 2.1.326, 1 run per case, sonnet judge):**

| | With founderstack | Without |
|---|---|---|
| Cases passed | **17 / 25** | 3 / 25 |
| The skill fired from a plain request | 24 / 25 | n/a |

<details>
<summary>Per skill</summary>

| Case | With | Without |
|---|---|---|
| collect-bills, council, draft-plan, founder-setup, grill, mac-compromise-check, memory-hygiene, model-router, new-skill, notion-worklog, shred-plan, vercel-triage, verify, worktree-janitor | pass | fail |
| free-disk, safe-migration, telegram-notify | pass | pass |
| founder-mode, morning-brief, pr-fold, reclaim, relay, ship-pr, spike, why | fail | fail |

</details>

Read these numbers with their limits:

- **One run per case.** Each cell is a single sample. founder-mode,
  morning-brief and reclaim passed in the previous run and failed in this one.
- **The eval sandbox has no working git.** relay, pr-fold and ship-pr are
  graded on what they plan to do, and they lose points when the sandbox blocks
  the step itself. ship-pr refused to merge, as it should, but could not reach
  the branch to draft the PR.
- **why did not fire** on a simple bug and answered correctly without it, but
  without the named assumption or the regression test the case asks for. Its
  description needs a stronger trigger.
- The first full run also found two real defects, both fixed before this run:
  a loophole that let ship-pr merge when asked, and a crash in free-disk on
  macOS bash 3.2.

Reproduce, with a cost cap:

```bash
claude plugin eval . --runs 1 --scaffold --allow-tools Bash Edit Write \
  --judge-model sonnet --max-cost-usd 15 --threshold 0
```

## Works everywhere, honestly

`SKILL.md` is portable. A few things are not, and [docs/harness.md](docs/harness.md)
says what each agent gets: how a skill is started, how a subagent is spawned,
how the agent asks you a question, how it waits on a background process. A
skill that needs a capability the agent lacks says so and does that step by
hand. It never pretends the step ran.

## Layout

```
skills/
  engineering/   plan, prove, ship, run unattended
  agent-ops/     notifications, worklog, memory, model choice
  company/       briefs, bills, prod triage
  machine/       CPU, disk, worktrees, security
  in-progress/   written but not trustworthy yet (not shipped)
  deprecated/    retired, kept because the reasoning is worth reading
evals/           one or more cases per skill: <skill>--<case>/
scripts/         check-skills.mjs (the lint CI runs), link-skills.sh
.out-of-scope/   ideas we decided against, and why
```

## Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md). In short: `/new-skill` scaffolds the
skill and its eval, `node scripts/check-skills.mjs` must pass, and a skill that
has never run end to end is a hypothesis.

## License

MIT
