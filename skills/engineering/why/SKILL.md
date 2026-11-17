---
name: why
description: "Find the root cause of a bug, not a plausible cause: reproduce, get one command that fails every time, minimise, test one hypothesis at a time, name the assumption that turned out false, then fix at the cause with a regression guard. Use when something is broken, throws, returns the wrong thing, regressed (\"this used to work\"), or the user asks \"why did X happen\"."
---

# /why: the cause, not a cause

A plausible cause is the most expensive kind of wrong answer: it gets fixed,
shipped and then the bug comes back. This loop does not let you propose a fix
until you can state which assumption turned out false.

## When NOT to use this

- Designing something new: `/grill`.
- Trying out options: `/spike`.
- "Clean up this module": that is a refactor. Suggest a separate task.

## The loop

Do the phases in order. Do not move on until the current one has a concrete
answer.

### 1. Reproduce: one red command

Get the exact failing case: the route, the input, the payload, the screenshot
(read the screenshot before you guess what it shows). Then turn it into **one
command** that:

- fails on this bug,
- fails every time,
- runs in seconds.

A test, a script, a `curl`, a CLI call. If you cannot reproduce it, ask one
targeted question ("Web or mobile? Which account?"), never "can you share more
info". If it only fails sometimes, the first job is to make it fail every time
(loop it, pin the seed, fix the clock).

### 2. Localise

Find the layer responsible: UI, API route, data, a third party, config, the
build. Read the code path from the symptom inward. Delegate a wide search to a
subagent and keep only its conclusion.

### 3. Minimise

Shrink the failing case to the smallest input that still fails. Fewer moving
parts make the cause visible.

### 4. One hypothesis at a time

Write the hypothesis down. Test it with the red command, a log line tagged so
you can find and remove it later (`[why-1234]`), a debugger or a read-only
query. Then form the next one. Never stack three guesses.

### 5. Name the violated assumption

Before you fix anything, answer: why does this bug exist? Not "which line is
wrong" but "which assumption was false". For example: *"the field `id` in the
tool output is always a row id from table A"*, but one path put an id from
table B in the same field. The symptom is a 404; the cause is the overloaded
field. If you cannot state the assumption in one sentence, keep digging.

### 6. Fix at the cause, smallest diff

Fix where the assumption breaks, not where the symptom shows. Before you edit,
answer two questions out loud:

1. Is this safe to ship to live users now, or does it need a flag or a
   migration window?
2. Which other call sites rely on the same false assumption? List them. Do not
   fix them in the same change unless the user agrees.

### 7. Regression guard

The red command from phase 1 becomes the guard: commit it as a test, or as a
script next to the repo's other repro scripts. Run it red on the old code (or
explain why you could not) and green on the fix. Skip the guard only with a
stated reason. Remove every temporary log line.

## Reply

```
Symptom:  <what the user saw>
Cause:    <the violated assumption, one sentence>
Where:    <file:line>
Fix:      <one sentence>
Proof:    <the red command, failing before and passing after, pasted>
At risk:  <other call sites with the same assumption, or "none found">
Not checked: <what you could not reproduce or verify>
```
