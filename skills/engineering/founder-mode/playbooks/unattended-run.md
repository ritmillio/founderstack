# Unattended run

You own a run nobody watches. It must end in a reviewable draft PR, not a surprise.

1. Get a duration or a set of done-criteria, plus a cap. No cap means 12 hours.
2. Turn every criterion into an executable check (see the relay skill's done-checks reference). A criterion that cannot be checked is rewritten or dropped, with the user's say.
3. *(if the user wants pings)* Set up `/telegram-notify` for run start, land, halt and end.
4. Start `/relay` on its own worktree and branch. Confirm the first leg started and the ledger is committed.
5. When the user comes back, `/relay report`: what landed, what is left, what needs them.

**Reply:** run id, worktree, branch, draft PR, the checks and their state, how to watch, how to stop, Not checked.
