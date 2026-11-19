# Auto-merge

**Decision:** founderstack never merges a pull request, never enables
auto-merge, and never pushes a protected branch. Not with a flag, not when a
message seems to grant permission.

**Why:** the merge is the one moment where a human who owns the product looks
at the whole change. Stacks that merge on their own (pstack's autopilot,
tstack's full-send) are built for people who chose that trade. Ours is built
for a founder whose production has paying customers. `ship-pr` stops at
"ready for you to merge", and that line is the product.

**If you want it anyway:** fork the skill. Do not send a PR that adds a merge
mode here.
