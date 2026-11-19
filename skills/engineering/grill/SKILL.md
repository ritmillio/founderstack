---
name: grill
description: "Pressure-test a plan or design before any code: read it in full, then ask the uncomfortable questions one at a time, each with a recommended answer, until every decision is resolved or parked as an open question. Use when the user says \"grill this\", \"what do you think of this plan\", \"is this a good idea\", or before work that touches data, auth, prompts, several surfaces or many files."
---

# /grill: settle the questions while changing your mind is cheap

A plan that survives `/grill` is one whose owner has answered every
uncomfortable question before code exists. It is the cheapest skill in the
stack. The expensive alternative is shipping the wrong design to live users.

## When NOT to use this

- A bug fix: the plan is "fix the bug". Use `/why`.
- A one-file edit or pure styling. Just do it.
- Work already in progress. Grilling halfway is sunk-cost theatre.
- A question only running code can answer: recommend `/spike` instead.

## Input

A plan file, a paragraph in chat, or an idea that is still only spoken. In the
last case, write it down in five lines first and confirm it. Read the whole
plan before the first question. Do not grill on the title.

## How to grill

1. **Find the facts yourself first.** Anything the code, the data or the docs
   can answer, look up (or send a subagent). Only decisions go to the human.
2. **One question at a time**, biggest unknown first. Each question carries
   your recommended answer, worded so that "yes" accepts it. Use the harness's
   question tool with options when it has one.
3. **"I don't know yet" is a good answer.** Record it as an open question with
   what it blocks, and move on.
4. **Stop when you stop learning**, or when the user is impatient. Then offer
   the rest as a written list they can answer later.

## The question library

A starting set, not a checklist. Ask only what matters for this plan.

- **Outcome.** What is the one-sentence result a user will see? If it needs two
  sentences, the plan does two things. What happens if we do nothing? Who asked
  for it?
- **Smallest version.** What is the smallest slice still worth shipping? Can it
  ship first? What is explicitly *not* in scope?
- **Blast radius.** If this is wrong, who notices first, and how bad is it? Is
  there a flag, a ramp or a rollback? Do existing rows, sessions or drafts still
  behave?
- **Data.** Does it need a migration? Is it reversible? Do the schema change and
  its migration land together?
- **AI parts.** Does a new tool overlap an existing one? Which prompts and models
  change, and what is the regression check? Do ids the model emits match what
  the UI looks up later?
- **Surfaces.** Web, mobile, extensions, email, API, background jobs: which ones
  need a change, and who builds each?
- **Observability.** How will we know it works in production? How will we know
  it broke? How do we undo it?
- **People.** Has the owner actually said yes, or did we infer it? Read back the
  one-sentence outcome and confirm.

## Reply

```
Plan in one sentence: <restated>
Resolved: <decision>: <answer>   (one per line)
Open:     <question> (blocks: <what>)
Recommendation: proceed | narrow to X | wait for Y | drop it
```

If the plan lives in a file, offer to write the resolved decisions and open
questions into it. Do not edit the file without a yes. You surface; the owner
decides.
