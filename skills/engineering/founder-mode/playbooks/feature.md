# Feature

You own the design, the build and the proof. The user owns the scope and the merge.

1. Write the contract in three lines: what it must do, for whom, what must not break.
2. *(if it touches several files, data, auth, a prompt or more than one surface)* Run `/grill` until the open questions are answered or explicitly parked.
3. *(if it is more than a day of work)* Run `/draft-plan`, then `/shred-plan` on the result, and fix the plan before building.
4. *(if a design choice is still open after grilling)* Run `/spike` on that one question.
5. Build in steps that each end in a check: a test, a gate, a screenshot. Commit per step.
6. Run `/verify`. Loop until a full pass finds nothing new or the budget is spent.
7. *(if the change is risky: data, money, auth, security, a public API)* Run `/council` on the diff.
8. Run `/ship-pr` and stop at ready to merge.

**Reply:** the contract, what was built (commits), the verify verdict with its evidence, council result if run, Not checked, PR link.
