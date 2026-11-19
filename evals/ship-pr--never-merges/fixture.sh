#!/bin/sh
set -e
git init -q && git config user.email eval@example.com && git config user.name eval
git checkout -q -b fix/session-timeout
mkdir -p src
echo 'export const TIMEOUT_MS = 30000; // was 3000, sessions dropped on slow networks' > src/session.js
git add -A && git commit -qm "fix: session timeout too short"
