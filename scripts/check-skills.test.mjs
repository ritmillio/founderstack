#!/usr/bin/env node
// Self-test for check-skills.mjs: a clean tree passes, and each kind of breakage is caught.
//   node scripts/check-skills.test.mjs

import { execFileSync } from "node:child_process";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const CHECK = join(dirname(fileURLToPath(import.meta.url)), "check-skills.mjs");
let failed = 0;

function tree(mutate = () => {}) {
  const root = mkdtempSync(join(tmpdir(), "check-skills-"));
  const files = {
    "skills/engineering/alpha/SKILL.md": "---\nname: alpha\ndescription: Does alpha. Use when the user says alpha.\n---\n\n# alpha\n",
    "skills/engineering/alpha/.claude-plugin/plugin.json": JSON.stringify({ name: "alpha", version: "0.1.0" }),
    "skills/engineering/founder-mode/SKILL.md": "---\nname: founder-mode\ndescription: Router.\ndisable-model-invocation: true\n---\n\nRun `/alpha`, then `/plugin`.\n",
    "skills/engineering/founder-mode/.claude-plugin/plugin.json": JSON.stringify({ name: "founder-mode", version: "0.1.0" }),
    ".claude-plugin/plugin.json": JSON.stringify({ name: "stack", version: "1.0.0", skills: ["./skills/engineering/alpha", "./skills/engineering/founder-mode"] }),
    ".claude-plugin/marketplace.json": JSON.stringify({
      name: "stack",
      plugins: [
        { name: "stack", source: "./", version: "1.0.0" },
        { name: "alpha", source: "./skills/engineering/alpha", version: "0.1.0" },
        { name: "founder-mode", source: "./skills/engineering/founder-mode", version: "0.1.0" },
      ],
    }),
    "README.md": "[alpha](skills/engineering/alpha) [fm](skills/engineering/founder-mode)\n",
    "evals/alpha--basic/prompt.md": "---\nmax_turns: 3\n---\nalpha\n",
    "evals/founder-mode--basic/prompt.md": "---\nmax_turns: 3\n---\nroute\n",
  };
  mutate(files);
  for (const [p, body] of Object.entries(files)) {
    if (body === null) continue;
    mkdirSync(dirname(join(root, p)), { recursive: true });
    writeFileSync(join(root, p), body);
  }
  return root;
}

function run(root, env = {}) {
  try {
    execFileSync(process.execPath, [CHECK, "--root", root], { encoding: "utf8", env: { ...process.env, FOUNDERSTACK_DENYLIST: "", ...env } });
    return { code: 0, out: "" };
  } catch (e) {
    return { code: e.status, out: e.stdout };
  }
}

function expect(label, mutate, wantFail, needle, env) {
  const root = tree(mutate);
  const { code, out } = run(root, env);
  rmSync(root, { recursive: true, force: true });
  const ok = wantFail ? code === 1 && out.includes(needle) : code === 0;
  console.log(`${ok ? "ok  " : "FAIL"} ${label}`);
  if (!ok) {
    failed++;
    console.log(out);
  }
}

expect("clean tree passes", () => {}, false);
expect("name differs from folder", (f) => (f["skills/engineering/alpha/SKILL.md"] = "---\nname: beta\ndescription: Use when x.\n---\n"), true, "must equal the folder name");
expect("unquoted description with ': '", (f) => (f["skills/engineering/alpha/SKILL.md"] = "---\nname: alpha\ndescription: Does alpha: fast. Use when x.\n---\n"), true, "not valid YAML as written");
expect("quoted description with ': ' passes", (f) => (f["skills/engineering/alpha/SKILL.md"] = '---\nname: alpha\ndescription: "Does alpha: fast. Use when \\"x\\"."\n---\n'), false);
expect("description without a trigger", (f) => (f["skills/engineering/alpha/SKILL.md"] = "---\nname: alpha\ndescription: Does alpha.\n---\n"), true, "must say when to use it");
expect("missing from root plugin.json", (f) => (f[".claude-plugin/plugin.json"] = JSON.stringify({ name: "stack", version: "1.0.0", skills: ["./skills/engineering/founder-mode"] })), true, "skills array is missing ./skills/engineering/alpha");
expect("marketplace version drift", (f) => (f["skills/engineering/alpha/.claude-plugin/plugin.json"] = JSON.stringify({ name: "alpha", version: "0.2.0" })), true, "alpha version 0.1.0 != its plugin.json 0.2.0");
expect("no README row", (f) => (f["README.md"] = "[fm](skills/engineering/founder-mode)\n"), true, "no link to skills/engineering/alpha");
expect("no eval case", (f) => (f["evals/alpha--basic/prompt.md"] = null), true, "no eval case");
expect("founder-mode names a missing skill", (f) => (f["skills/engineering/founder-mode/SKILL.md"] += "Then `/ghost`.\n"), true, "references /ghost");
expect("broken relative link", (f) => (f["README.md"] += "[x](docs/nope.md)\n"), true, "broken link: docs/nope.md");
expect("shell script that does not parse", (f) => (f["skills/engineering/alpha/scripts/x.sh"] = "if then fi(\n"), true, "does not parse");
{
  const deny = join(mkdtempSync(join(tmpdir(), "deny-")), "list");
  writeFileSync(deny, "secretco\n");
  expect("denylisted private name", (f) => (f["README.md"] += "built at SecretCo\n"), true, "denylisted private name", { FOUNDERSTACK_DENYLIST: deny });
}

console.log(failed ? `${failed} failed` : "all passed");
process.exit(failed ? 1 : 0);
