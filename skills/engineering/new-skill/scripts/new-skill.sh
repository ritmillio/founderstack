#!/usr/bin/env bash
#
# new-skill.sh: scaffold a skill, its first eval case, and every registration it needs.
#
#   new-skill.sh <name> --description "What it does. Use when ..." [--category engineering] [--repo DIR]
#
# Two layouts, detected from the repo:
#   plugin repo  (.claude-plugin/marketplace.json + skills/<category>/):  skills/<category>/<name>/,
#                its .claude-plugin/plugin.json, a marketplace entry, the root plugin.json skills
#                array (via scripts/check-skills.mjs --fix when present), and evals/<name>--basic/.
#   any repo     the first existing of .agents/skills, .claude/skills (default .agents/skills):
#                <dir>/<name>/SKILL.md and <dir>/<name>/evals/basic/.
# Refuses to overwrite anything. Needs bash and node.

set -euo pipefail

NAME="${1:-}"; shift || true
DESC=""; CAT="engineering"; REPO=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --description) DESC="$2"; shift 2 ;;
    --category)    CAT="$2";  shift 2 ;;
    --repo)        REPO="$2"; shift 2 ;;
    -h|--help)     sed -n '2,15p' "$0"; exit 0 ;;
    *) echo "unknown flag: $1" >&2; exit 2 ;;
  esac
done

[[ -n "$NAME" ]] || { echo "usage: new-skill.sh <name> --description '...'" >&2; exit 2; }
[[ "$NAME" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || { echo "name must be kebab-case" >&2; exit 2; }
[[ -n "$DESC" ]] || DESC="TODO: what it does. Use when the user says ..."
REPO="${REPO:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
AUTHOR="$(git -C "$REPO" config user.name 2>/dev/null || echo "")"

if [[ -f "$REPO/.claude-plugin/marketplace.json" && -d "$REPO/skills/$CAT" ]]; then
  LAYOUT=plugin; DIR="$REPO/skills/$CAT/$NAME"; EVAL="$REPO/evals/$NAME--basic"
else
  LAYOUT=plain; BASE="$REPO/.agents/skills"
  [[ -d "$REPO/.agents/skills" ]] || { [[ -d "$REPO/.claude/skills" ]] && BASE="$REPO/.claude/skills"; }
  DIR="$BASE/$NAME"; EVAL="$DIR/evals/basic"
fi
[[ -e "$DIR" ]] && { echo "${DIR#"$REPO"/} already exists" >&2; exit 2; }
[[ -e "$EVAL" ]] && { echo "${EVAL#"$REPO"/} already exists" >&2; exit 2; }

mkdir -p "$DIR" "$EVAL/graders"
cat > "$DIR/SKILL.md" <<MD
---
name: $NAME
description: $DESC
---

# /$NAME: one-line hook

One paragraph: the problem this solves and the mistake it prevents.

## When to use this

-

## When NOT to use this

- (and the skill that fits better)

## Steps

1.

## Traps

- The sentence that stops someone repeating a mistake.

## Reply

What the skill says back: the outcome first, the evidence, then what was not checked.
MD

cat > "$EVAL/prompt.md" <<MD
---
runs: 3
max_turns: 15
allowed_tools: [Read, Glob, Grep, Skill]
tags: [$NAME]
---

TODO: a request phrased the way a user would say it, without naming the skill.
MD
cat > "$EVAL/graders/triggered.md" <<MD
---
type: tool_used
tool: Skill
input_match: '"skill"\s*:\s*"(?:[\w-]+:)?$NAME"'
---
MD
cat > "$EVAL/graders/outcome.md" <<MD
---
type: llm
weight: 2
---

TODO: PASS if the final answer ... FAIL otherwise. Grade what a good outcome looks like, not the wording.
MD

if [[ $LAYOUT == plugin ]]; then
  mkdir -p "$DIR/.claude-plugin"
  NAME="$NAME" DESC="$DESC" CAT="$CAT" AUTHOR="$AUTHOR" REPO="$REPO" node --input-type=module -e '
    import { readFileSync, writeFileSync } from "node:fs";
    const { NAME, DESC, CAT, AUTHOR, REPO } = process.env;
    const root = JSON.parse(readFileSync(`${REPO}/.claude-plugin/plugin.json`, "utf8"));
    const plugin = { name: NAME, description: DESC, version: "0.1.0",
      ...(root.author ? { author: root.author } : AUTHOR ? { author: { name: AUTHOR } } : {}),
      ...(root.homepage ? { homepage: root.homepage, repository: root.repository } : {}),
      license: root.license || "MIT" };
    writeFileSync(`${REPO}/skills/${CAT}/${NAME}/.claude-plugin/plugin.json`, JSON.stringify(plugin, null, 2) + "\n");
    const mp = `${REPO}/.claude-plugin/marketplace.json`;
    const m = JSON.parse(readFileSync(mp, "utf8"));
    m.plugins.push({ name: NAME, source: `./skills/${CAT}/${NAME}`, description: DESC, version: "0.1.0" });
    writeFileSync(mp, JSON.stringify(m, null, 2) + "\n");
  '
  [[ -f "$REPO/scripts/check-skills.mjs" ]] && node "$REPO/scripts/check-skills.mjs" --fix >/dev/null || true
  echo "created  skills/$CAT/$NAME/SKILL.md (+ .claude-plugin/plugin.json)"
  echo "created  evals/$NAME--basic/ (prompt + trigger grader + outcome grader)"
  echo "updated  .claude-plugin/marketplace.json, .claude-plugin/plugin.json"
  echo "todo     a README row linking skills/$CAT/$NAME"
else
  echo "created  ${DIR#"$REPO"/}/SKILL.md"
  echo "created  ${EVAL#"$REPO"/}/ (prompt + trigger grader + outcome grader)"
fi
