#!/bin/sh
set -e
git init -q && git config user.email eval@example.com && git config user.name eval
mkdir -p src/webhooks docs
cat > src/webhooks/stripe.js <<'JS'
export async function handle(event, db) {
  if (event.type === "payment_intent.succeeded") {
    await db.credit(event.data.object.customer, event.data.object.amount);
  }
}
JS
git add -A && git commit -qm "init"
