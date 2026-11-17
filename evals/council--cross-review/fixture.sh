#!/bin/sh
set -e
git init -q && git config user.email eval@example.com && git config user.name eval
mkdir -p src
cat > src/auth.js <<'JS'
export function checkSession(token, now = Date.now()) {
  if (!token) return false;
  if (token.expiresAt && token.expiresAt < now) return false;
  return token.userId != null;
}
JS
cat > CHANGE.diff <<'D'
--- a/src/auth.js
+++ b/src/auth.js
@@
 export function checkSession(token, now = Date.now()) {
   if (!token) return false;
-  if (token.expiresAt < now) return false;
+  if (token.expiresAt && token.expiresAt < now) return false;
   return token.userId != null;
 }
D
git add -A && git commit -qm "init"
