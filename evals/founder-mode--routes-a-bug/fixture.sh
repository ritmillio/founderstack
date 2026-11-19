#!/bin/sh
set -e
git init -q && git config user.email eval@example.com && git config user.name eval
mkdir -p src
cat > src/cart.js <<'JS'
// Sum of line totals in a cart.
export const total = (lines) => lines.map((l) => l.price * l.qty).reduce((a, b) => a + b);
JS
cat > package.json <<'J'
{ "name": "shop", "type": "module", "scripts": { "test": "node --test" } }
J
git add -A && git commit -qm "init"
