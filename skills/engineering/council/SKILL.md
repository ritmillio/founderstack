---
name: council
description: Get a change reviewed by several models from different vendors, in rounds, until they agree or the budget ends: stable finding ids, blocker/should/nit judged against the stated intent, fixes between rounds, a score table in the PR body. Without other vendors it runs fresh reviewers with different lenses and says so. Use when the user says "council", "second opinion", "cross-review this", or before shipping a risky change (data, money, auth, security, public API).
---

# /council: reviewers who did not write it, and do not think alike

One model reviewing its own work finds its own blind spots last. A council
puts the diff in front of reviewers from different vendors, keeps every finding
under a stable id, fixes between rounds, and stops when they agree or the
budget runs out. Running out of budget is not approval.

## When NOT to use this

- A small, low-risk change: `/verify` is enough.
- Before the change exists: `/grill` or `/shred-plan`.
- When you have not yet run the gates. Fix the known reds first; reviewers'
  time goes to what you cannot see.

## Steps

1. **Write the intent** in three lines: what the change must do, for whom, and
   what must not break. Every finding is judged against this, not against taste.
2. **Seat the council.** Use the `Council` seats in `.agents/founderstack.md`.
   Otherwise detect which vendor CLIs are installed and signed in, and run each
   read-only, non-interactively:
   - Codex CLI: `codex exec --sandbox read-only "<brief>"`
   - Gemini CLI: `gemini -p "<brief>"`
   - other agents with a headless mode, per their `--help`
   Check each CLI's `--help` before the first call; flags change. A seat that is
   not available is reported as missing, never quietly swapped for another
   model. If no other vendor is available, seat three fresh subagents of the
   current model with different lenses (correctness, security and data,
   simplicity and scope) and say plainly that the council is single-vendor.
3. **Brief every seat the same way:** the intent, the diff range
   (`git diff <base>...HEAD`), the repo's invariants, and this severity scale:
   - **blocker**: breaks the intent, loses data, opens a security hole, or
     breaks a hard rule;
   - **should**: a real defect or risk that does not break the intent;
   - **nit**: style or preference.
   Ask each seat for findings with file:line and the input that breaks it, plus
   a score out of 10 for the change as it stands. Seats only read; nobody edits
   the checkout while a seat is reading it.
4. **Triage as results arrive.** Give each distinct finding a stable id (F1,
   F2, ...) in a ledger, merge duplicates across seats, and drop findings that
   come with no evidence. Verify every blocker yourself before you act on it.
5. **Fix between rounds.** Fix the blockers and the shoulds you accept, in new
   commits. If a fix grew the diff beyond the intent, cut it back first.
   Decline a finding only with a written reason.
6. **Next round** with the same seats, on the new head, with the ledger. Ask
   each seat to confirm or reopen each finding by id. Budget: 3 rounds, 5 for
   security or data changes.
7. **Stop** when no seat has an open blocker and the seats agree, or when the
   budget ends. At the budget's end, list what is still open; do not call it
   approved.
8. **Record.** If there is a PR, add a `## Council review` table to its body
   (propose the edit first if the PR is not yours). Write "no score" when a seat
   gave none; never invent one.

## Reply

```
Council: <seats, or "single-vendor: 3 lenses">   Rounds: <n of budget>
Round  <seat A>  <seat B>  <seat C>
1      6/10      5/10      no score
2      9/10      8/10      8/10
Fixed:    F1 blocker (file:line, commit), F3 should (...)
Declined: F2 nit: <reason>
Open:     <ids still open, or "none">
Not checked: <seats missing, what no seat looked at>
```
