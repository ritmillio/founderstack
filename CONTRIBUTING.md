# Contributing

## What belongs here

A skill earns its place when it encodes a workflow that would otherwise be
re-explained every time: the same files touched in the same order, the gotchas
that have already cost someone a day, the discipline that is obvious in
hindsight and forgotten under pressure.

Not worth a skill: a one-off task, something a plain script does better, or
anything already covered by an existing skill.

## Writing one

```bash
bash skills/engineering/new-skill/scripts/new-skill.sh my-skill --category engineering --description "What it does. Use when ..."
```

The `description` is load-bearing. It is the only thing an agent sees when
deciding whether the skill is relevant, so lead with the trigger and be
specific. "Formats code" is useless; "Reformat and lint changed files before a
commit. Use when the user says commit, push, or asks to clean up a diff" is not.

Structure the body so it can be followed by an agent with no memory of this
conversation:

- Say when NOT to use it, not just when to use it.
- Number the steps. One concrete action each.
- Name exact paths and exact commands.
- Put the traps in. A skill's real value is usually the sentence that stops
  someone repeating a mistake.
- Keep `SKILL.md` under about 150 lines. Longer material goes in `references/`
  and gets linked from the body, so it is loaded only when needed.

## Staying portable

Skills here must work in agents other than Claude Code:

- Do not assume a slash command exists.
- Project rules come from the host repo's `.agents/founderstack.md`, never from the skill.
- Do not hardcode `${CLAUDE_PLUGIN_ROOT}`. Resolve the skill directory at
  runtime; `skills/relay/SKILL.md` shows the pattern.
- Do not assume a package manager, a directory layout, or an operating system.
  If something is genuinely OS-specific, isolate it and say plainly what each
  platform gets — see `skills/relay/scripts/keep-awake.sh`.
- Project-specific rules do not belong in the skill. Have it read a config file
  from the host repository instead.

## Before opening a PR

```bash
node scripts/check-skills.mjs          # the lint CI runs; must be 0 errors
node scripts/check-skills.test.mjs     # if you touched the lint
claude plugin validate .
claude plugin eval . --case '<name>--*' --runs 3 --scaffold --max-cost-usd 3
```

Every shipped skill needs at least one eval case in `evals/<name>--<case>/`:
a prompt phrased the way a user would ask (without naming the skill), a
`triggered` grader, and an `outcome` grader that a judge can apply as PASS or
FAIL. Grade the outcome, not the wording. A score near the no-plugin baseline
with the trigger failing means the description does not fire.

Optional private-name guard: list words that must never appear (client names,
internal project names) one per line in `.denylist` (gitignored) or in a file
named by `$FOUNDERSTACK_DENYLIST`. The lint fails on any match.

A skill that is written but not yet trustworthy goes in `skills/in-progress/`
rather than shipping half-done. A skill you stop believing in moves to
`skills/deprecated/` instead of being deleted: the reasoning stays readable.
An idea we decided against gets a file in `.out-of-scope/`.

Then actually run the skill end to end. A skill that has never been executed is
a hypothesis.
