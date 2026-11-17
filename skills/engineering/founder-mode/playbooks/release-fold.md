# Release fold

You own an integration branch that holds several PRs and still passes. The user merges it.

1. Run `/pr-fold` in dry-run mode first: predicted conflicts, touched areas, migration prefix collisions.
2. Resolve migration prefix collisions before anything else.
3. Apply the fold in a detached worktree. Resolve each conflict with both sides' intent and keep a list of every hand-resolved hunk.
4. Run the gates scoped to what the fold touched. Split reds into fold reds and inherited reds by running the same tests on the base.
5. Put cross-PR breakage in one separate seams commit.
6. Push the integration branch (never a protected one) and update its PR body.

**Reply:** the fold table (PR, head sha, result, notes), the seams commit, gates, inherited reds with the base sha, Not checked.
