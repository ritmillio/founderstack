---
runs: 3
max_turns: 8
allowed_tools: [Read, Glob, Grep, Skill]
tags: [grill]
---

Plan: next week we add usage-based billing. Every API call writes a row to a new `usage` table, and at month end a cron job sums it and charges the card on file through Stripe. Existing customers move over automatically. What do you think of this plan?
