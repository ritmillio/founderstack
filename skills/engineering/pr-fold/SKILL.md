---
name: pr-fold
description: Fold several open PR branches into an integration or release branch: dry run for conflicts and migration prefix collisions, merge in a detached worktree, resolve with both sides' intent, gate what the fold touched, put cross-PR breakage in one seams commit, push the integration branch. Never a protected branch, never a GitHub merge. Use when the user says "fold #N into ...", "put these PRs on the release branch", or "one release PR with all open PRs".
---

# /pr-fold: many PRs, one integration branch, still green

When a founder ships through one release PR, someone has to fold the feature
PRs into it. Every rule below exists because a fold once went wrong: a
protected branch got the merges, a wholesale "ours" dropped someone's keys, two
migrations took the same number.

## Hard stops

- The target is never a protected branch: `main`, `master`, `staging`,
  `development`, `production`, plus whatever `.agents/founderstack.md` lists.
  `fold.sh` refuses them, and so do you.
- Never merge a PR on GitHub (no `gh pr merge`, no merge button, no API call),
  not even into the integration branch. A fold is a local `git merge` and a
  push.
- Never fold in a shared checkout. Work in a detached worktree of
  `origin/<target>`.
- Check HEAD in the same command as every commit.
- Never rename a PR's head branch; GitHub closes the PR.

## Steps

`$SKILL_DIR` is this skill's folder; resolve it at runtime (where this
`SKILL.md` lives).

1. **Resolve the target and the PRs.** The target is the integration branch the
   user names, or the head of the release PR they name
   (`gh pr view <n> --json headRefName`). If a PR's author or relay is still
   committing, fold it at a pinned sha and say "re-fold from <sha>" later.
2. **Dry run.** It predicts conflicts against the running tip, lists the
   touched areas and flags migration prefix collisions. It changes nothing.
   ```bash
   bash "$SKILL_DIR/scripts/fold.sh" --into release/1.4 [--migrations db/migrations] 601 586
   ```
   Exit 0 clean, 1 conflict, 2 migration prefix collision, 3 both.
3. **Migration prefixes first.** Two PRs adding the same `NNNN_` prefix, or a
   PR adding a prefix the target already has, get renumbered during the fold.
   A migration renamed after it ran anywhere counts as a different migration.
   Read the repo's migration rules before you renumber.
4. **Apply** in the detached worktree. It stops at the first conflict:
   ```bash
   bash "$SKILL_DIR/scripts/fold.sh" --into release/1.4 --apply 601 586
   ```
   Merge message: `merge: #N <head-branch> into <target>`.
5. **Resolve with both sides' intent**, never "ours" or "theirs" wholesale.
   Keep a list of every hunk you resolved by hand: the file, what each side
   wanted, what you kept. Known shapes:
   - two implementations of the same idea: keep the later or more complete one
     and port what the other has uniquely;
   - two blocks added at the same spot: keep both, in a deliberate order;
   - a whole catalog or locale file in conflict: diff against the default
     branch afterwards, because taking one side drops the other's keys.
   Then `git -C "$WT" commit --no-edit` and rerun `--apply` with the PRs that
   are left.
6. **Gates, scoped to what the fold touched.** Use the `Gates` section of the
   config; the dry run's areas tell you which ones apply. For a release fold,
   run the full suite once.
7. **Fold reds or inherited reds?** Run the same failing tests on
   `origin/<target>` in a second detached worktree (never `git stash`). Only
   reds that pass on the base belong to the fold. Name inherited reds with the
   base sha, and do not fix them inside the fold.
8. **Seams.** Breakage between PRs (one PR's new guard test fails on another
   PR's new route; a moved module the other PR still imports) goes into ONE
   separate commit: `fix(merge): seams after folding #A, #B into <target>`,
   with each seam listed in the body. Never hide seam fixes in a merge commit.
9. **Push and record.** The script prints the push command. It checks first
   that nobody pushed meanwhile. If the ancestry check fails, merge
   `origin/<target>` in, gate again, and retry. Update the integration PR's
   body with the folded list (PR, head sha, conflicts resolved, seams). A
   source PR based on the target is marked merged by GitHub on its own. A
   source PR based on the default branch stays open unless the user asked for
   one release PR; then close it with a comment that links the integration PR.
10. Remove the fold worktree when you are done (`git worktree remove`).

## Reply

```
fold -> <target> @ <new head sha>   (base <old sha>)
PR     head sha   result         notes
#601   592eef6    merged         docs only
#593   1a2b3c4    conflicts 3    card: #594 kept, #593 planner ported
seams  <sha> fix(merge): ...     2 seams: ...
gates  typecheck 0 | tests: 2 reds inherited (base <sha>) | migrations ok
pushed <remote> HEAD:<target> | PR #602 body updated | #601 closed
Not checked: <what you did not run>
```
