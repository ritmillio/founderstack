#!/bin/sh
set -e
git init -q && git config user.email eval@example.com && git config user.name eval
mkdir -p docs src
echo 'export const charge = () => {};' > src/payments.js
cat > docs/plan.md <<'MD'
# Plan: move invoices to the new ledger
1. Extend the existing ledger in src/billing/ledger.ts with an invoices table.
2. Backfill all invoices from Stripe in one script run on production.
3. Switch reads to the ledger.
Done when: it works well.
MD
git add -A && git commit -qm "init"
