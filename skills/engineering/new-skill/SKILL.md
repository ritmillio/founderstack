---
name: new-skill
description: Turn a workflow you keep re-explaining into a skill an agent can follow cold: a trigger-first description, when not to use it, numbered steps with exact commands, the traps, and a first eval case that checks it fires from a natural prompt and improves the outcome. Use when the user says "make this a skill", "codify this", "create a skill", or the same instructions have been given twice.
---

# /new-skill: write it once, prove it helps

A skill earns its place when it encodes a workflow that would otherwise be
explained again every time: the same files in the same order, a trap that
already cost someone a day, a discipline that everyone forgets under pressure.
A skill that has never run is a hypothesis. This one ships with an eval that
checks the skill fires and makes the result better than no skill.

## When NOT to use this

- A one-off task. Just do it.
- A plain script would do it better. Write the script; maybe a skill calls it.
- An existing skill already covers it. Improve that one instead.

## Steps

`$SKILL_DIR` is this skill's folder; resolve it at runtime.

1. **Collect the five inputs.** Ask only for what is missing, one question at
   a time:
   - the trigger: what the user will say, and the kebab-case name (short verb
     or noun, not a built-in command);
   - the goal in one sentence;
   - the inputs (paths, PR numbers, free text);
   - the done state (files written, commits, a report);
   - the traps that already bit someone.
2. **Scaffold.** It refuses to overwrite anything:
   ```bash
   bash "$SKILL_DIR/scripts/new-skill.sh" <name> --description "<what it does>. Use when <trigger>." [--category engineering]
   ```
   In a plugin repo like founderstack it also writes the plugin manifest, the
   marketplace entry, the root skills list and `evals/<name>--basic/`. In any
   other repo it writes to `.agents/skills/<name>/` (or `.claude/skills/`) with
   an `evals/basic/` folder.
3. **Write the description.** It is the only part the model sees when it
   decides whether to load the skill. What it does, then "Use when ..." with
   the user's actual words. A skill only the user should start (it writes
   config, spends money, or is expensive) gets `disable-model-invocation: true`
   and a one-line description.
4. **Write the body** for an agent with no memory of this conversation:
   - when NOT to use it, and which skill fits better;
   - numbered steps, one concrete action each, with exact paths and commands;
   - the traps, because the sentence that stops a repeat mistake is the value;
   - a Reply block: the outcome first, the evidence, then what was not checked;
   - under about 150 lines; longer material goes in `references/` and is linked.
5. **Stay portable.** Do not assume a slash command exists, a package manager,
   a directory layout or an OS. Resolve the skill's own folder at runtime
   instead of hardcoding a plugin variable. Project rules come from the host
   repo's config (`.agents/founderstack.md`), never from the skill.
6. **Write the eval case** in the scaffolded folder:
   - `prompt.md`: the request as a user would phrase it, *without* naming the
     skill. If the skill needs files, add a `case.yaml` with
     `context.scaffold_script` that builds a tiny repo.
   - `graders/triggered.md`: already checks that the skill fired.
   - `graders/outcome.md`: what a good result contains, as a PASS/FAIL rule a
     judge can apply. Grade the outcome, not the wording.
7. **Check it.** In founderstack: `node scripts/check-skills.mjs`. Then run the
   eval with and without the plugin:
   ```bash
   claude plugin eval . --case '<name>--*' --runs 3 --scaffold --max-cost-usd 3
   ```
   A score difference near zero with the trigger grader failing means the
   description does not fire. Fix the description, not the grader.
8. **Run it once for real**, end to end, on a real task. Then add the README
   row.

## Traps

- A description that says only what the skill is ("Formats code") never fires.
  Lead with what it does and when: "Reformat changed files before a commit. Use
  when the user says commit or push."
- Negative instructions ("don't do X") without the reason get ignored. Say why.
- Copying another project's skill text: keep its licence notice and credit it.
  Copying the idea and writing your own is cleaner.

## Reply

The skill path, the eval case path, the lint result, the eval scores with and
without the skill, and Not checked.
