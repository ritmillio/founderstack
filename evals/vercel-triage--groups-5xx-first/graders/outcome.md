---
type: llm
weight: 2
---

PASS only if ALL hold: (1) it puts the 500 errors on /api/checkout first as the main problem; (2) it de-duplicates repeated events and groups by status and path; (3) the counts it gives are consistent with the file (4 unique 500 events on /api/checkout, 2 unique 404s on /favicon.ico). FAIL otherwise.
