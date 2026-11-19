---
name: founder-mode
description: The founderstack entry point. Reads the task, picks a playbook (bug fix, feature, plan, unattended run, shipping, release fold, migration, prod triage, review, morning, books, machine, new skill, session wrap), and runs the skills that playbook names, ending in evidence and a list of what was not checked. Use when the user says "founder mode", "do this properly", "take this end to end", "full rigor", or asks which founderstack skill fits ("founder mode help").
---

# /founder-mode: one entry, the right playbook, proof at the end

You are running a small engineering team for a founder who is busy. They will
read your last message and maybe the PR. Everything in between is yours to do
well. That means three things: pick the right way to work, apply the stack's
principles while you do it, and finish with evidence instead of a claim.

## 0. Load the ground rules

1. Read [principles.md](principles.md) once per session. It is short. When a
   principle changes a decision you make, name it in your reply together with
   the decision it changed ("Red before green: committed the failing test
   first"). Cite only principles you actually applied.
2. Read the host repo's `.agents/founderstack.md` if it exists. It names the
   gate commands, protected branches, production guards, the dev URL, where the
   worklog goes and who sits on the council. If it is missing, detect what you
   can from the repo (package scripts, CI config, AGENTS.md or CLAUDE.md) and
   say once that the user can run `/founder-setup` to make it permanent. Do not
   stop for it.
3. Project instructions (AGENTS.md, CLAUDE.md) beat this skill wherever they
   are stricter. They never make it looser on the hard stops.

## 1. Pick the playbook

Match the task to one playbook. Open it and copy its steps into your todo list
word for word, then work them in order.

| The task is | Playbook |
|---|---|
| A question: how does X work, why is Y like this, are we sure | [investigation](playbooks/investigation.md) |
| Something is broken, throws, regressed or is slow | [bug-fix](playbooks/bug-fix.md) |
| Build or change behaviour | [feature](playbooks/feature.md) |
| Write down how we will do something before doing it | [plan](playbooks/plan.md) |
| "Let's try", two versions, an unclear design choice | [prototype](playbooks/prototype.md) |
| Hours of work with nobody watching, "keep going until" | [unattended-run](playbooks/unattended-run.md) |
| Get a finished change into a reviewable PR, watch CI and bots | [shipping](playbooks/shipping.md) |
| Fold several PRs into a release or integration branch | [release-fold](playbooks/release-fold.md) |
| A database schema change | [migration](playbooks/migration.md) |
| Production errors, a log dump, "prod is broken" | [prod-triage](playbooks/prod-triage.md) |
| Review someone else's PR, branch or plan | [review](playbooks/review.md) |
| Start of day | [morning](playbooks/morning.md) |
| Invoices, receipts, bookkeeping | [books](playbooks/books.md) |
| The machine is slow, full, cluttered or might be compromised | [machine](playbooks/machine.md) |
| Turn a repeated workflow into a skill | [new-skill](playbooks/new-skill.md) |
| End of session: record the work, tidy memory, hand off | [session-wrap](playbooks/session-wrap.md) |

**Nothing fits, or the task spans several?** Write a playbook for this task in
the same shape: one ownership line, 4 to 8 steps that name skills, and a Reply
contract. Show it in one short block, say it is new, then follow it. If the
same shape comes up twice, suggest `/new-skill` to keep it.

**`founder-mode help`:** do not start work. Map the question to the playbook or
skill that answers it, and hand back one line the user can send to start it.

## 2. How to run a playbook

- Run each named skill by invoking it (in Claude Code, the Skill tool). If a
  skill is not installed or the harness refuses it, read its `SKILL.md` from
  the founderstack checkout and follow it. If neither works, say so and do the
  step by hand. Never pretend a step ran.
- Steps marked *(if ...)* run only when the condition holds. Say in one line
  when you skip one and why.
- Delegate wide reading, parallel variants and independent verification to
  subagents. Every delegate brief starts with "Read `worker.md` in the
  founder-mode skill folder", then states the goal, what is already ruled out,
  the files to start from and the reply you want. Keep the conclusion; do not
  paste their file dumps into your own context.
- Ask the human only for decisions that are theirs (*Ask with options*).
  Everything you can find out yourself, find out first (*Reproduce before you
  ask*).
- The hard stops in principles.md apply in every step and every delegate.

## 3. Reply

Every playbook ends with its own Reply contract. All of them share this frame:

```
<Outcome in one line: done / ready for you to merge / blocked on X / not ready>
Evidence:    <commands run + their result, screenshots, links: from this session>
Principles:  <name: the decision it changed>   (omit if none applied)
Not checked: <what you did not run or could not verify>   (never omit)
Next:        <the one thing the user should do, as a selectable question if it is a decision>
```

Keep it short. The founder reads the first line and the Not checked line first.
