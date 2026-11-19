---
name: spike
description: Build a throwaway prototype that answers one design or behaviour question inside a time budget, show the variants side by side, get the user to pick, then delete it. Use when the user says "let's try", "what if we", "show me two versions", "spike this", or a choice is unclear and a static mockup would not settle it.
---

# /spike: answer one question, then throw the code away

A spike exists to answer a question and then be deleted. It informs the real
build. It is not a draft of production code, and it never gets merged.

## When to spike

- A UI choice with several plausible answers (drawer, sidebar or inline?).
- A behaviour question (does the model actually use this new field?).
- A layout that only feels right or wrong on a real device.
- A library or API whose docs are ambiguous, where 30 lines settle it.

## When NOT to spike

- "Just build the feature." That is the work, not a spike.
- A tiny style tweak. Try it in place.
- Anything touching the database schema, auth or production config. There is
  no safe throwaway path for those.

## Steps

1. **State the question** in one sentence. If you cannot, you are not ready.
2. **State the success test.** "I will know when I can see both layouts side
   by side and pick one." "The prompt works if 4 of 5 sample inputs cite a
   source."
3. **State the budget** (time, or "until the comparison is on screen"). When it
   runs out, stop and decide: extend with a reason, or kill it.
4. **Pick the lightest place that proves it:**
   - a dev-only route in the app, guarded so it cannot ship (for example behind
     a non-production check), with variants side by side on one page;
   - a standalone script for logic or a model behaviour (cheapest model that
     can show the behaviour, a hard stop on any loop);
   - a hidden screen on mobile, never wired into navigation.
5. **Build it.** Hardcode everything that is not under test: mock data, fake
   auth, copied types. Use the real design tokens anyway, so what you see
   transfers to the real build. No tests, no migrations, no new dependency
   unless the dependency is what you are evaluating. First line of every spike
   file: `SPIKE: <question>. Delete after <date or condition>.`
6. **Show the result.** Screenshots of each variant, or the script output.
7. **Get the decision** with options. Do not assume the winner.
8. **Plan the real build** in one paragraph: which variant, which files it
   will really touch, what changes from the spike, what is deferred.
9. **Delete the spike** (or list exactly what to delete). Never merge it.

## Reply

```
Question: <one sentence>
Answer:   <variant chosen, value measured, behaviour seen>
Evidence: <screenshot paths, output>
Next:     <one paragraph for the real build>
Cleanup:  <deleted / to delete>
```

## Refuse these

- "Spike it and merge it if it works." Then it is not a spike. Build it
  properly.
- "Spike a refactor." Refactor spikes turn into rewrites. Grill the case first.
