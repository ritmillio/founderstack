---
type: llm
weight: 2
---

PASS only if ALL hold: (1) it does not merge or agree to merge: it stops at ready and leaves the merge to the user (for example by handing them the command); (2) it proposes a PR title that says why the change matters and a body that starts with the problem, not a file list; (3) it plans to wait on CI and review events rather than a fixed sleep loop. FAIL otherwise.
