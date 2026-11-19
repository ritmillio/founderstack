# Credits

founderstack was built after studying three public skill stacks. We copied
ideas and structure, never text or code. Each row names where an idea came from
and where it lives here, so you can compare and so the credit is precise.

| Idea | Came from | Lives here |
|---|---|---|
| One router in front of every skill; the task picks a playbook | pstack, `skills/poteto-mode/SKILL.md` | `skills/engineering/founder-mode/SKILL.md` |
| Playbooks: an ownership line, steps that name skills, a fixed Reply contract | pstack, `skills/poteto-mode/playbooks/*.md` | `founder-mode/playbooks/*.md` |
| Principles indexed by when they apply; cite the principle and the decision it changed | pstack, poteto-mode "Principles" section and the `principle-*` skills | `founder-mode/principles.md` (one file, not one skill per principle) |
| One rules file every delegate reads first | pstack, `skills/poteto-mode/worker.md` | `founder-mode/worker.md` |
| The author never verifies their own work; a verdict belongs to one commit | pstack, `playbooks/shipping.md` | principles.md "The author does not verify", `verify` step 0 |
| Encode a repeated lesson as structure: architecture, then types or lint, then tests, docs last | pstack, `principle-encode-lessons-in-structure` | principles.md "Encode the lesson in structure"; `scripts/check-skills.mjs` |
| Docs linted against the file tree | pstack, `scripts/check-pstack-docs.mjs` | `scripts/check-skills.mjs` (README rows, manifests, playbook references) |
| Proof plus a yes/no gate on the latest commit | tstack, `skills/full-send/SKILL.md` | `ship-pr` step 7, principles.md "Prove it" |
| Wait on PR events, never a sleep loop; stay silent when nothing happened | tstack, `skills/babysit-pr/scripts/pr-wait` | `skills/engineering/ship-pr/scripts/pr-watch.sh` (our own, bash + gh) |
| Review by models of different vendors, looped until they agree; a missing seat is reported, never swapped | tstack, `skills/council/SKILL.md` | `skills/engineering/council/SKILL.md` |
| blocker / should / nit against the stated intent, stable finding ids, a round budget that is not approval | tstack, `skills/sol-loop/SKILL.md` | `council` steps 3 to 7, principles.md "Budget, then stop" |
| PR title says why it matters; the body leads with the problem | tstack, `skills/file-pr/SKILL.md` | `ship-pr` steps 2 and 3 |
| One setup skill writes per-repo config; skills stay generic | mattpocock/skills, `skills/engineering/setup-matt-pocock-skills` | `founder-setup`, `.agents/founderstack.md` |
| Debugging starts with one command that is red, deterministic and fast | mattpocock/skills, `skills/engineering/diagnosing-bugs` | `why` phase 1, principles.md "Red before green" |
| Grilling: one question at a time, each with a recommended answer | mattpocock/skills, `skills/productivity/grilling` | `grill` |
| Rejected ideas are written down, one file each | mattpocock/skills, `.out-of-scope/` | `.out-of-scope/` |
| Skills the model may start vs. skills only the user starts | mattpocock/skills, `.agents/invocation.md` | `new-skill` step 3 |

Earlier founderstack skills (`relay`, `shred-plan`, `draft-plan`, `reclaim`,
`telegram-notify`, `safe-migration`, `vercel-triage`, `morning-brief`,
`worktree-janitor`, `memory-hygiene`, `free-disk`, `collect-bills`,
`mac-compromise-check`) were written before this study and have no counterpart
in the three stacks.

All three projects are MIT licensed: pstack (c) 2026 Lauren Tan, tstack (c)
2026 Theo Browne, mattpocock/skills (c) 2026 Matt Pocock. Because no text or
code was copied, no third-party notice is required. If any is copied later,
its notice goes into `THIRD_PARTY_NOTICES` in the same change.
