#!/bin/sh
set -e
git init -q && git config user.email eval@example.com && git config user.name eval
cat > package.json <<'J'
{ "name": "app", "scripts": { "dev": "next dev -p 3000", "typecheck": "tsc --noEmit", "test": "vitest run", "lint": "eslint ." } }
J
mkdir -p .github/workflows
cat > .github/workflows/ci.yml <<'Y'
on: { pull_request: {}, push: { branches: [main, release] } }
jobs:
  ci:
    runs-on: ubuntu-latest
    steps:
      - run: npm ci
      - run: npm run typecheck
      - run: npm test
Y
echo "DATABASE_URL=postgres://prod.example.com/app" > .env.production.example
git add -A && git commit -qm "init"
