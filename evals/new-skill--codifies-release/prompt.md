---
runs: 3
max_turns: 20
allowed_tools: [Read, Glob, Grep, Skill, Bash, Edit, Write]
tags: [new-skill]
---

Every time I cut a release I explain the same steps to the agent: bump the version in package.json, add a CHANGELOG entry, commit, tag vX.Y.Z, push the tag. Make that reusable for this repo.
