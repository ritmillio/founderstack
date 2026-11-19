---
type: llm
weight: 2
---

PASS only if ALL hold: (1) it checks the codebase and reports that src/billing/ledger.ts, which the plan says exists, does not; (2) it flags the missing rollback or failure plan; (3) it flags 'works well' as a done-criterion nobody can verify; (4) findings are ranked by severity. FAIL otherwise.
