#!/usr/bin/env node
// check-skills.mjs: the lint every skill in founderstack must pass. Zero dependencies (Node 20+).
//
//   node scripts/check-skills.mjs            # check the repo, exit 1 on any error
//   node scripts/check-skills.mjs --fix      # rewrite the skills array in .claude-plugin/plugin.json
//   node scripts/check-skills.mjs --root <dir>   # check another tree (the self-test uses this)
//
// Private-name guard: put one word per line in a file named by $FOUNDERSTACK_DENYLIST, or in
// ./.denylist (gitignored). Every tracked text file is searched for those words. The list never
// goes into the repo, because the list itself would leak the names.

import { execFileSync } from "node:child_process";
import { existsSync, readdirSync, readFileSync, statSync, writeFileSync } from "node:fs";
import { dirname, join, relative, resolve } from "node:path";

const args = process.argv.slice(2);
const FIX = args.includes("--fix");
const rootArg = args.indexOf("--root");
const ROOT = resolve(rootArg >= 0 ? args[rootArg + 1] : join(dirname(new URL(import.meta.url).pathname), ".."));

const SHIPPED = ["engineering", "agent-ops", "company", "machine"];
const PARKED = ["in-progress", "deprecated"];
const MAX_DESCRIPTION = 1024;
const WARN_LINES = 300;
const TRIGGER = /\b(use|invoke|run) (it |this )?(when|whenever|at|before|after|for|to)\b|\btrigger/i;
// Slash tokens in founder-mode that are commands of a harness, not skills.
const HARNESS_COMMANDS = new Set(["plugin", "mcp", "loop", "clear", "compact", "help", "model", "config", "feedback"]);

const errors = [];
const warnings = [];
const err = (file, msg) => errors.push(`${file}: ${msg}`);
const warn = (file, msg) => warnings.push(`${file}: ${msg}`);
const rel = (p) => relative(ROOT, p) || ".";
const read = (p) => readFileSync(p, "utf8");
const readJson = (p) => {
  try {
    return JSON.parse(read(p));
  } catch (e) {
    err(rel(p), `invalid JSON (${e.message})`);
    return null;
  }
};

// --- frontmatter ---------------------------------------------------------------------------
// Enough YAML for SKILL.md: top-level `key: value` pairs, quoted or bare, nested blocks skipped.
function frontmatter(text) {
  const m = text.match(/^---\n([\s\S]*?)\n---\n/);
  if (!m) return null;
  const out = {};
  for (const line of m[1].split("\n")) {
    const kv = line.match(/^([A-Za-z][\w-]*):\s*(.*)$/);
    if (!kv) continue;
    let v = kv[2].trim();
    if ((v.startsWith('"') && v.endsWith('"')) || (v.startsWith("'") && v.endsWith("'"))) v = v.slice(1, -1);
    out[kv[1]] = v;
  }
  return out;
}

// --- discover skills -----------------------------------------------------------------------
const skillsDir = join(ROOT, "skills");
const skills = [];
for (const cat of existsSync(skillsDir) ? readdirSync(skillsDir) : []) {
  const catDir = join(skillsDir, cat);
  if (!statSync(catDir).isDirectory()) continue;
  if (![...SHIPPED, ...PARKED].includes(cat)) {
    err(rel(catDir), `unknown category; use one of ${[...SHIPPED, ...PARKED].join(", ")}`);
    continue;
  }
  for (const name of readdirSync(catDir)) {
    const dir = join(catDir, name);
    if (!statSync(dir).isDirectory()) continue;
    skills.push({ cat, name, dir, shipped: SHIPPED.includes(cat), path: `./skills/${cat}/${name}` });
  }
}
const names = new Set(skills.map((s) => s.name));

// --- per-skill checks ----------------------------------------------------------------------
const seen = new Map();
for (const s of skills) {
  const md = join(s.dir, "SKILL.md");
  const f = rel(md);
  if (seen.has(s.name)) err(f, `duplicate skill name, also at ${seen.get(s.name)}`);
  seen.set(s.name, f);
  if (!existsSync(md)) {
    err(rel(s.dir), "missing SKILL.md");
    continue;
  }
  const text = read(md);
  const fm = frontmatter(text);
  if (!fm) {
    err(f, "missing YAML frontmatter");
    continue;
  }
  if (!/^[a-z0-9]+(-[a-z0-9]+)*$/.test(s.name)) err(f, "folder name must be kebab-case");
  if (fm.name !== s.name) err(f, `frontmatter name "${fm.name}" must equal the folder name "${s.name}"`);
  const desc = fm.description || "";
  if (!desc) err(f, "description is empty");
  if (desc.length > MAX_DESCRIPTION) err(f, `description is ${desc.length} chars (max ${MAX_DESCRIPTION})`);
  const userOnly = fm["disable-model-invocation"] === "true";
  if (desc && !userOnly && !TRIGGER.test(desc)) {
    err(f, 'model-invoked skill: the description must say when to use it ("Use when ...")');
  }
  const lines = text.split("\n").length;
  if (lines > WARN_LINES) warn(f, `${lines} lines; move detail into references/ (aim for under ${WARN_LINES})`);

  if (!s.shipped) continue;

  const pj = join(s.dir, ".claude-plugin", "plugin.json");
  if (!existsSync(pj)) err(rel(s.dir), "missing .claude-plugin/plugin.json");
  else {
    const p = readJson(pj);
    if (p && p.name !== s.name) err(rel(pj), `name "${p.name}" must be "${s.name}"`);
    if (p && !p.version) err(rel(pj), "missing version");
    s.version = p?.version;
  }
}

// --- manifests -----------------------------------------------------------------------------
const shipped = skills.filter((s) => s.shipped).sort((a, b) => a.path.localeCompare(b.path));
const rootPluginPath = join(ROOT, ".claude-plugin", "plugin.json");
const rootPlugin = existsSync(rootPluginPath) ? readJson(rootPluginPath) : null;
if (!rootPlugin) err(".claude-plugin/plugin.json", "missing root plugin manifest");
else {
  const want = shipped.map((s) => s.path);
  const have = rootPlugin.skills || [];
  if (FIX) {
    rootPlugin.skills = want;
    writeFileSync(rootPluginPath, `${JSON.stringify(rootPlugin, null, 2)}\n`);
    console.log(`fixed: .claude-plugin/plugin.json lists ${want.length} skills`);
  } else {
    for (const p of want) if (!have.includes(p)) err(".claude-plugin/plugin.json", `skills array is missing ${p} (run --fix)`);
    for (const p of have) if (!want.includes(p)) err(".claude-plugin/plugin.json", `skills array lists ${p}, which is not a shipped skill (run --fix)`);
  }
}

const marketPath = join(ROOT, ".claude-plugin", "marketplace.json");
const market = existsSync(marketPath) ? readJson(marketPath) : null;
if (!market) err(".claude-plugin/marketplace.json", "missing marketplace manifest");
else {
  const entries = new Map(market.plugins.map((p) => [p.name, p]));
  const bundle = entries.get(rootPlugin?.name);
  if (!bundle || bundle.source !== "./") err(".claude-plugin/marketplace.json", `no bundle entry "${rootPlugin?.name}" with source "./"`);
  else if (bundle.version && bundle.version !== rootPlugin.version) {
    err(".claude-plugin/marketplace.json", `bundle version ${bundle.version} != plugin.json ${rootPlugin.version}`);
  }
  for (const s of shipped) {
    const e = entries.get(s.name);
    if (!e) err(".claude-plugin/marketplace.json", `no entry for ${s.name}`);
    else {
      if (e.source !== s.path) err(".claude-plugin/marketplace.json", `${s.name} source is ${e.source}, want ${s.path}`);
      if (e.version && s.version && e.version !== s.version) {
        err(".claude-plugin/marketplace.json", `${s.name} version ${e.version} != its plugin.json ${s.version}`);
      }
    }
  }
}

// --- README lists every shipped skill ------------------------------------------------------
const readmePath = join(ROOT, "README.md");
if (existsSync(readmePath)) {
  const readme = read(readmePath);
  for (const s of shipped) {
    if (!readme.includes(`(${s.path.slice(2)})`) && !readme.includes(`(${s.path})`)) {
      err("README.md", `no link to ${s.path.slice(2)} (every shipped skill gets a row)`);
    }
  }
}

// --- every shipped skill has at least one eval case ----------------------------------------
const evalsDir = join(ROOT, "evals");
const cases = existsSync(evalsDir) ? readdirSync(evalsDir).filter((d) => statSync(join(evalsDir, d)).isDirectory()) : [];
for (const c of cases) {
  const dir = join(evalsDir, c);
  if (c === "results" || c === "mocks") continue;
  if (!existsSync(join(dir, "prompt.md")) && !existsSync(join(dir, "case.yaml"))) err(rel(dir), "eval case needs prompt.md or case.yaml");
  const owner = c.split("--")[0];
  if (!names.has(owner)) err(rel(dir), `eval case must be named <skill>--<case>; no skill "${owner}"`);
}
for (const s of shipped) {
  if (!cases.some((c) => c.startsWith(`${s.name}--`))) err(rel(s.dir), `no eval case (add evals/${s.name}--<case>/)`);
}

// --- founder-mode references resolve to real skills ----------------------------------------
const fm = skills.find((s) => s.name === "founder-mode");
if (fm) {
  for (const file of walk(fm.dir).filter((p) => p.endsWith(".md"))) {
    const text = read(file).replace(/```[\s\S]*?```/g, "");
    for (const m of text.matchAll(/`\/([a-z0-9-]+)`/g)) {
      if (!names.has(m[1]) && !HARNESS_COMMANDS.has(m[1])) err(rel(file), `references /${m[1]}, which is not a skill in this repo`);
    }
  }
}

// --- relative links in markdown resolve ----------------------------------------------------
const tracked = trackedFiles();
for (const file of tracked.filter((p) => p.endsWith(".md"))) {
  const abs = join(ROOT, file);
  const text = read(abs).replace(/```[\s\S]*?```/g, "").replace(/`[^`\n]*`/g, "");
  for (const m of text.matchAll(/\]\(([^)\s]+)(?:\s+"[^"]*")?\)/g)) {
    const target = m[1].split("#")[0];
    if (!target || /^[a-z][a-z0-9+.-]*:/i.test(target)) continue;
    if (!existsSync(resolve(dirname(abs), decodeURI(target)))) err(file, `broken link: ${m[1]}`);
  }
}

// --- scripts parse -------------------------------------------------------------------------
for (const file of tracked) {
  const abs = join(ROOT, file);
  try {
    if (file.endsWith(".sh")) execFileSync("bash", ["-n", abs], { stdio: "pipe" });
    if (file.endsWith(".py")) execFileSync("python3", ["-c", "import ast,sys; ast.parse(open(sys.argv[1]).read())", abs], { stdio: "pipe" });
    if (file.endsWith(".mjs") || file.endsWith(".js")) execFileSync(process.execPath, ["--check", abs], { stdio: "pipe" });
  } catch (e) {
    err(file, `does not parse: ${String(e.stderr || e.message).trim().split("\n")[0]}`);
  }
}

// --- private-name denylist -----------------------------------------------------------------
const denyFile = process.env.FOUNDERSTACK_DENYLIST || join(ROOT, ".denylist");
if (existsSync(denyFile)) {
  const words = read(denyFile).split("\n").map((w) => w.trim()).filter((w) => w && !w.startsWith("#"));
  const deny = words.length ? new RegExp(`\\b(${words.map((w) => w.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")).join("|")})\\b`, "i") : null;
  for (const file of deny ? tracked : []) {
    let text;
    try {
      text = read(join(ROOT, file));
    } catch {
      continue;
    }
    text.split("\n").forEach((line, i) => {
      if (deny.test(line)) err(`${file}:${i + 1}`, "contains a denylisted private name");
    });
  }
}

// --- helpers + report ----------------------------------------------------------------------
function walk(dir) {
  return readdirSync(dir).flatMap((n) => {
    const p = join(dir, n);
    return statSync(p).isDirectory() ? walk(p) : [p];
  });
}
function trackedFiles() {
  try {
    const out = execFileSync("git", ["-C", ROOT, "ls-files", "--cached", "--others", "--exclude-standard"], { encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] });
    return out.split("\n").filter((p) => p && existsSync(join(ROOT, p)) && statSync(join(ROOT, p)).isFile());
  } catch {
    return walk(ROOT).map((p) => relative(ROOT, p)).filter((p) => !p.startsWith(".git/"));
  }
}

for (const w of warnings) console.log(`warn  ${w}`);
for (const e of errors) console.log(`error ${e}`);
console.log(`check-skills: ${skills.length} skills (${shipped.length} shipped), ${cases.length} eval cases, ${errors.length} errors, ${warnings.length} warnings`);
process.exit(errors.length ? 1 : 0);
