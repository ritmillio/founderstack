# Bug fix

You own the fix and its proof. The user owns the merge.

1. Run `/why`: reproduce, get one red command, minimise, name the violated assumption.
2. Commit the red check first (a test, or a script under the repo's usual place) so the fix can be proven against it.
3. Make the smallest fix at the cause. List other call sites with the same flaw instead of fixing them.
4. Run the gates from `.agents/founderstack.md` and the red check, now green.
5. Run `/verify` with a fresh agent as the verifier (*The author does not verify*).
6. *(if the user wants a PR)* Run `/ship-pr` and stop when it is ready for them to merge.

**Reply:** symptom, cause (the violated assumption), fix (file:line), the red check failing before and passing after (pasted), gates, other call sites at risk, Not checked, PR link.
