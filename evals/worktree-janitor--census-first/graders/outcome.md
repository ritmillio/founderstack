---
type: llm
weight: 2
---

PASS only if ALL hold: (1) it first builds a census of each worktree (uncommitted changes, unpushed commits, PR state); (2) it gives each a verdict such as safe / ask / keep; (3) it removes nothing until the user picks, and re-checks before removing. FAIL otherwise.
