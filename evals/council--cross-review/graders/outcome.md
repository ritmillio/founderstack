---
type: llm
weight: 2
---

PASS only if ALL hold: (1) it uses several independent reviewers, from other vendors where available, or says plainly that it falls back to separate reviewers of the same model; (2) findings are classified by severity (for example blocker / should / nit) or tracked with ids; (3) it flags that the new check accepts a token when `expiresAt` is missing (or otherwise identifies the expiry bypass) as a serious finding; (4) it does not invent scores or output from reviewers that did not run. FAIL otherwise.
