#!/usr/bin/env bash
# link-skills.sh: symlink every shipped skill of this checkout into an agent's skills folder.
# Use it to develop skills live, or to repair links after the v1 folder move
# (skills moved from productivity/, bookkeeping/, security/ into engineering/, agent-ops/,
# company/, machine/).
#
#   scripts/link-skills.sh                         # dry run into ~/.agents/skills
#   scripts/link-skills.sh --apply                 # do it
#   scripts/link-skills.sh --target ~/.claude/skills --apply
#
# Only links that already point into a founderstack checkout (a path ending in
# skills/<category>/<name>, old or new categories) are re-pointed. A link to anything else, or a
# real directory with the same name, is never touched: it is reported, because skills called
# verify, why or grill are common and may be your own.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="$HOME/.agents/skills"; APPLY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --apply) APPLY=1; shift ;;
    -h|--help) sed -n '2,13p' "$0"; exit 0 ;;
    *) echo "unknown flag: $1" >&2; exit 2 ;;
  esac
done

[ $APPLY = 1 ] && mkdir -p "$TARGET"
n_new=0; n_fix=0; n_ok=0; n_skip=0
for md in "$REPO"/skills/{engineering,agent-ops,company,machine}/*/SKILL.md; do
  src="$(dirname "$md")"; name="$(basename "$src")"; dst="$TARGET/$name"
  if [ -L "$dst" ]; then
    cur="$(readlink "$dst")"
    if [ "$cur" = "$src" ]; then n_ok=$((n_ok + 1)); continue; fi
    case "${cur%/}" in
      */skills/engineering/"$name"|*/skills/productivity/"$name"|*/skills/bookkeeping/"$name"|*/skills/security/"$name"|\
      */skills/agent-ops/"$name"|*/skills/company/"$name"|*/skills/machine/"$name")
        echo "relink  $name: $cur -> $src"; n_fix=$((n_fix + 1))
        [ $APPLY = 1 ] && ln -sfn "$src" "$dst" ;;
      *)
        echo "skip    $name: $dst links to $cur, which is not a founderstack checkout (left alone)"; n_skip=$((n_skip + 1)) ;;
    esac
  elif [ -e "$dst" ]; then
    echo "skip    $name: $dst is a real directory, not a link (left alone)"; n_skip=$((n_skip + 1))
  else
    echo "link    $name -> $src"; n_new=$((n_new + 1))
    [ $APPLY = 1 ] && ln -s "$src" "$dst"
  fi
done
MODE='dry run'; [ $APPLY = 1 ] && MODE='applied'
echo "$MODE: $n_new new, $n_fix re-pointed, $n_ok already right, $n_skip skipped. Target: $TARGET"
[ $APPLY = 1 ] || echo "add --apply to make the change"
