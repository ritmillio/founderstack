# Migration

You own a schema change that applies cleanly and loses nothing.

1. Run `/safe-migration`: read the repo's migration rules first, then take the next free prefix from disk and from the default branch.
2. Write the migration and the schema change in the same commit. Grep the SQL for silent drops.
3. Apply it on a disposable or dev database only. Never on production, never a shared push.
4. Run the gates and any migration check the repo has.
5. Continue with the [feature](feature.md) or [bug-fix](bug-fix.md) playbook for the code that uses it.

**Reply:** migration file, prefix check, the drop grep result, where it was applied and the result, Not checked.
