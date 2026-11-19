---
name: verify
description: "Prove a finished change works before calling it done: run the repo gates, read the diff as a hostile reviewer, write the missing edge-case tests, drive the real app, and loop until a full pass finds nothing new. Ends in SHIP, SHIP WITH NOTES or NOT READY plus what was not checked. Use when the user says \"verify\", \"make sure this works\", \"is this ready\", or before opening or un-drafting a PR."
---

# /verify: done means proven

"Finished" is a claim, not a fact. This skill treats the change as a PR from a
stranger and loops gates, review, tests and a live drive until a whole pass
finds nothing new. It ends with a verdict you can defend.

## When NOT to use this

- Finding the cause of a reported bug: `/why`.
- Critiquing a plan before code exists: `/grill` or `/shred-plan`.
- Nothing was changed and there is no branch diff: say so and stop.

## 0. Scope and contract

1. `git status`, then `git diff <base>...HEAD --stat` plus uncommitted changes.
   The base is the default branch unless the user names another. The diff plus
   what this session built is the scope.
2. Check you are on the branch you think you are, in the same command as
   anything you run. Another session may have switched it. A dev server on the
   usual port may be serving a different worktree.
3. Write a three-line contract: what the change must do, for whom, and what must
   not break. Judge every finding against the contract, not against taste.
4. **Whose branch is it?** If you are reviewing someone else's branch or PR,
   you are in **report mode**: you change nothing on their branch. Tests you
   write go in a scratch worktree, and fixes become suggestions in the report.
   On your own branch you fix as you go.
5. **The author does not verify.** If you wrote the change in this session,
   hand phases 2 to 4 to a fresh subagent with the contract and the diff range,
   and keep the verdict theirs. Say in the reply that you did.

## The loop

Phases 1 to 4 are one pass. If any phase led to a code change, run a whole new
pass. Stop when a pass finds nothing new, or after 3 passes. At that point,
report what is still open instead of looping.

### 1. Gates

Run the commands under `Gates` in `.agents/founderstack.md`. Without that file,
use what CI runs (read `.github/workflows/`), else the obvious package scripts.
Run the full test suite at least once before the verdict. A red gate is a
finding. A gate that is also red on the base branch is inherited: name it with
the base sha and do not count it against the change.

### 2. Adversarial read

Read the whole diff. For each changed file, ask what input, state or user makes
it wrong:

- edge cases: empty, null, zero-length, first run with no data, maximum length,
  non-ASCII text, repeated or concurrent calls, an aborted request or stream;
- error paths: what the user sees when a call fails; a silent `catch` is a
  finding;
- auth and tenancy: every new query scoped to the right account; every new
  route behind the right auth; no object id taken from the client unchecked;
- the repo's invariants (the `Invariants` section, AGENTS.md or CLAUDE.md):
  each violation is a finding;
- other surfaces: does the change need a mobile, extension, email or API
  counterpart that was not touched?

### 3. Missing tests

For each edge case that is testable as plain logic, write the test before you
decide whether the code handles it, and let the test tell you. Put it next to
the existing suite. A new test that fails is a finding: fix the code (in report
mode, describe the fix instead), not the test, unless the test misread the
contract. What can only be checked in the
running app goes to phase 4.

### 4. Live drive (when there is a UI or an API)

1. Use the dev server from `Live drive` in the config, or start one in the
   background and say so. Confirm it serves this worktree.
2. Drive it with the harness's browser tool if there is one (for example
   Claude in Chrome or Playwright), else `curl` for an API.
3. Walk the happy path from the entry point a real user uses, then two or three
   abuse paths: empty submit, double click, back button mid-flow, very long
   input, reload mid-request.
4. After each flow, read the console and the network log. A console error on
   the happy path is a finding even when the page looks fine.
5. If the change touched styling, check light and dark theme and phone width.
6. Never point anything at production (the `Production guard` section).

If a live drive is impossible, say so in the report. Do not skip it silently.

## Reply

```
Verdict: SHIP | SHIP WITH NOTES | NOT READY, and one sentence why
Passes:  <one line per pass: what it found>
Fixed:   <file:line, what was wrong, what covers it now>
Tests:   <added, what they pin; final gate output, verbatim: green or red>
Not checked: <paths not tested, flows not driven, prod-only behaviour>
```

Do not soften NOT READY to be polite. The skill exists so that "done" means
proven.
