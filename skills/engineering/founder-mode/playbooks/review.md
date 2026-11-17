# Review

You own a review that finds real problems and nothing invented.

1. Read the intent first: the PR body, the linked issue or plan. Judge the change against that intent, not against taste.
2. Run `/verify` as the reviewer on the branch: gates, adversarial read, missing tests, a live drive where there is a surface.
3. *(if the change is risky or the author asked for it)* Run `/council` for reviews from other models.
4. Keep only findings that come with evidence: a failing command, a reproduction, a file:line with the input that breaks it.
5. *(if it is someone else's PR)* Propose comments to the user before posting any (*Propose, then apply*).

**Reply:** verdict (SHIP / SHIP WITH NOTES / NOT READY), findings ranked blocker, should, nit, each with evidence, Not checked.
