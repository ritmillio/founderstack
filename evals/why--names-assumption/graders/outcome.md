---
type: llm
weight: 2
---

PASS only if ALL hold: (1) it identifies `user.discount || 0.1` in src/pricing.js as the cause, because `||` treats an explicit 0 as missing; (2) it states the false assumption (that a falsy discount means no discount was set); (3) it proposes `??` (or an explicit undefined/null check) as the fix and a check or test that reproduces the bug. FAIL otherwise.
