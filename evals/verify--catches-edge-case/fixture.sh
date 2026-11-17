#!/bin/sh
set -e
git init -q && git config user.email eval@example.com && git config user.name eval
mkdir -p src test
cat > src/slugify.js <<'JS'
export function slugify(title) {
  return title.toLowerCase().trim().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
}
JS
cat > test/slugify.test.js <<'JS'
import { test } from "node:test";
import assert from "node:assert";
import { slugify } from "../src/slugify.js";
test("basic", () => assert.equal(slugify("Hello World"), "hello-world"));
JS
cat > package.json <<'J'
{ "name": "blog", "type": "module", "scripts": { "test": "node --test" } }
J
git add -A && git commit -qm "init"
