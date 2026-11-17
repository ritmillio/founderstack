---
name: ship-pr
description: Take a finished branch to "ready for you to merge": file a PR whose title says why it matters and whose body leads with the problem, wait on CI and review bots with an event-driven waiter, fix real findings, answer the rest, and stop when the latest commit is green. Never merges. Use when the user says "ship it", "open a PR", "file a PR", "babysit the PR", or "get this ready to merge".
---

# /ship-pr: from finished branch to "ready for you to merge"

The last mile is where agents waste the most: a PR body that lists changed
files, a sleep loop that polls CI for an hour, review-bot comments fixed
blindly or ignored. This skill files a PR a busy person can judge in ten
seconds, waits on real events only, and stops at the line the founder owns:
the merge.

## Hard stops

- Never merge, never enable auto-merge, never push a protected branch.
- Never force-push a branch someone else also pushes to. Use
  `--force-with-lease` on your own branch only, and only after a rebase you
  were asked for.

## Steps

`$SKILL_DIR` is this skill's folder; resolve it at runtime.

1. **Preflight.** You are on your own branch, not a protected one (check in
   the same command as the push). The gates from `.agents/founderstack.md` pass
   on the head commit. There are no secrets in the diff: grep the diff for
   tokens, keys, `.env` content and connection strings.
2. **Title: why it matters**, not what changed. If the repo uses a convention
   (`fix(scope): ...`, a ticket id), follow it.
   - Bad: `Update chat-stream.ts and add test`
   - Good: `fix(chat): answers no longer stop mid-sentence on slow networks`
3. **Body: problem first.**
   ```markdown
   <The problem in the user's words: what they saw, when, how often. 1-3 lines.>

   <The fix in plain words: what changes for them. 1-3 lines. Not a file list.>

   **Evidence:** <the check that failed before and passes now; screenshots; gate results>
   **Not checked:** <what was not verified>
   **Risk:** <one-way or two-way door; what breaks if this is wrong; how to undo>
   ```
   Add the project's required lines (ticket links, attribution) at the end.
   Leave out anything the reviewer does not need.
4. **Open it.** Use a draft when the project wants drafts first or CI is known
   to be red; otherwise a ready PR, so review bots run.
   `gh pr create --title "..." --body-file <file> [--draft]`.
5. **Read what is already there** (reviews, comments, failed checks) before you
   wait. Then start the waiter in the background:
   ```bash
   bash "$SKILL_DIR/scripts/pr-watch.sh" <pr> --until green
   ```
   In Claude Code, run it with the Monitor tool; elsewhere, as a background
   process. Do not write your own sleep loop. When the waiter prints nothing,
   you do nothing. Exit 0 = green, 1 = needs you, 3 = timeout.
6. **On "needs you":**
   - a failed check: open its log (`gh run view <id> --log-failed`), reproduce
     locally, fix in a new commit. If the same check is red on the base branch,
     it is inherited: say so and do not fix it here.
   - a review comment: judge it against the PR's intent. A real defect gets a
     fix in a new commit and a short reply that links it. A wrong or
     out-of-scope comment gets a one-line reason. Do not grow the PR to please
     a bot.
   - `BEHIND` or `DIRTY`: rebase or merge the base as the repo prefers, re-run
     the gates, push.
   Then start the waiter again.
7. **Stop** when the latest commit is green and no change request is open. If
   the same check fails three times after real fix attempts, stop and report;
   do not keep pushing.
8. *(if the project logs work)* Update the record with the PR link
   (`/notion-worklog`).

## Traps

- Green on an old commit is not green. The waiter reports the head sha; check
  it matches what you pushed.
- Review bots repeat themselves. Answer a repeated comment once and link the
  earlier answer.
- A PR comment posted for the user goes out under their name: plain, short, no
  "as an AI" lines.

## Reply

```
PR:       <url> (<draft|ready>)   head <sha>
CI:       <green | red: check names> on <sha>
Fixed:    <finding -> commit>
Declined: <finding -> reason>
Not checked: <...>
Ready for you to merge.     (or: Blocked on <X>)
```
