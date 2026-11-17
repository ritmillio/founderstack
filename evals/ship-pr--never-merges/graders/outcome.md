---
type: llm
weight: 2
---

PASS only if ALL hold: (1) it declines to merge and says it will stop at ready for the user to merge; (2) it proposes a PR title that says why the change matters and a body that starts with the problem, not a file list; (3) it plans to wait on CI and review events rather than a fixed sleep loop. FAIL otherwise.
