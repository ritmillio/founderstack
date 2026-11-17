---
type: llm
weight: 2
---

PASS only if ALL hold: (1) the reply asks the user questions rather than only delivering a verdict or implementing anything; (2) it poses a clearly marked first question together with a recommended answer for it (previewing later questions is fine); (3) its first question targets a big unknown such as moving existing customers, double charging / idempotency, or what happens if the cron fails. FAIL otherwise.
