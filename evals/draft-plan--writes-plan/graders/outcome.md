---
type: llm
weight: 2
target:
  source: file
  path: docs/webhook-plan.md
---

PASS only if ALL hold: (1) the plan has a diagnosis section; (2) it states what is in and out of scope; (3) it splits the work into steps that each name how they will be proven (a test, a check); (4) it lists open questions. FAIL otherwise.
