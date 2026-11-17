#!/bin/sh
set -e
git init -q && git config user.email eval@example.com && git config user.name eval
echo '{ "name": "lib", "version": "1.2.0" }' > package.json
printf '# Changelog\n\n## 1.2.0\n- first\n' > CHANGELOG.md
git add -A && git commit -qm "init"
