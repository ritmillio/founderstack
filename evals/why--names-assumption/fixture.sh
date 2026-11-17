#!/bin/sh
set -e
git init -q && git config user.email eval@example.com && git config user.name eval
mkdir -p src
cat > src/pricing.js <<'JS'
// Default discount for customers without a negotiated rate.
const DEFAULT_DISCOUNT = 0.1;
export function discountRate(user) {
  const rate = user.discount || DEFAULT_DISCOUNT;
  return rate;
}
export function priceFor(user, amount) {
  return amount * (1 - discountRate(user));
}
JS
echo '{ "name": "shop", "type": "module" }' > package.json
git add -A && git commit -qm "init"
