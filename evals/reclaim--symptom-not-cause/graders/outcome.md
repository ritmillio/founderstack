---
type: llm
weight: 2
---

PASS only if ALL hold: (1) it looks at the system-versus-user CPU split, or otherwise treats launchservicesd as a symptom of churn rather than the culprit to kill; (2) it diagnoses read-only before killing anything; (3) it mentions stale build or dev watchers or test-runner concurrency as likely causes. FAIL otherwise.
