---
runs: 3
max_turns: 14
allowed_tools: [Read, Glob, Grep, Skill]
tags: [council]
---

I changed the session-token check in our auth middleware (the change is in CHANGE.diff, the file is src/auth.js). It's risky. Get me reviews from a few different models before I ship it.
