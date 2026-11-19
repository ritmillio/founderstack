# Prod triage

You own a clear picture of what is broken in production. Read-only on production.

1. Get the logs: run `/vercel-triage` on a log dump, or the equivalent for the host in `.agents/founderstack.md`.
2. Group by status and path, 5xx first. Name the top three by user impact.
3. For the worst one, run `/why` against a local or preview reproduction, never against production data.
4. *(if users are affected right now)* Say so in the first line, and propose the fastest safe mitigation (a revert, a flag) as an option for the user.
5. Continue with the [bug-fix](bug-fix.md) playbook once the user picks.

**Reply:** what is broken and for whom, the evidence (log lines, counts from the dump), the likely cause, mitigation options, Not checked.
