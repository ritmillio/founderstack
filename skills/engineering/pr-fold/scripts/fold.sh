#!/usr/bin/env bash
# fold.sh: fold PR heads into an integration branch. Never a protected branch, never a push.
#
#   fold.sh --into release/1.4 601 586             # dry run: predicts conflicts, touched areas and
#                                                  # migration prefix collisions; changes nothing
#   fold.sh --into release/1.4 --apply 601 586     # merges into a detached worktree, stops at the
#                                                  # first conflict; never pushes
#
# Options: --worktree <dir>     default: <repo>-fold-<target> next to the repo
#          --repo <dir>         default: the git toplevel of the cwd
#          --migrations <dir>   repo-relative dir of NNNN_*.sql files to check for prefix collisions
#          --protect <a,b>      extra protected branches (main, master, staging, development,
#                               production and the `branches:` line of .agents/founderstack.md
#                               are always protected)
# Exit: 0 clean, 1 conflict predicted or hit, 2 migration prefix collision, 3 both (bitfield).
# bash 3.2 compatible (macOS /bin/bash): no associative arrays, no mapfile.
set -euo pipefail

TARGET=""; APPLY=0; WT=""; REPO=""; PRS=""; MIG_DIR=""; PROTECT="main master staging development production"
while [ $# -gt 0 ]; do
  case "$1" in
    --into) TARGET="$2"; shift 2 ;;
    --apply) APPLY=1; shift ;;
    --worktree) WT="$2"; shift 2 ;;
    --repo) REPO="$2"; shift 2 ;;
    --migrations) MIG_DIR="${2%/}"; shift 2 ;;
    --protect) PROTECT="$PROTECT $(printf '%s' "$2" | tr ',' ' ')"; shift 2 ;;
    -h|--help) sed -n '2,19p' "$0"; exit 0 ;;
    *) PRS="$PRS ${1#\#}"; shift ;;
  esac
done

die() { echo "fold: $*" >&2; exit 1; }
[ -n "$TARGET" ] || die "--into <integration-branch> is required"
[ -n "$PRS" ] || die "give at least one PR number"
REPO="${REPO:-$(git rev-parse --show-toplevel)}"
G() { git -C "$REPO" "$@"; }

CFG="$REPO/.agents/founderstack.md"
if [ -f "$CFG" ]; then
  PROTECT="$PROTECT $(sed -n 's/^- branches:[[:space:]]*\([^#]*\).*/\1/p' "$CFG" | tr ',' ' ')"
  PUSH_REMOTE="$(sed -n 's/^- push remote:[[:space:]]*\([^[:space:]#]*\).*/\1/p' "$CFG" | head -1)"
fi
PUSH_REMOTE="${PUSH_REMOTE:-origin}"
T="${TARGET#origin/}"
for B in $PROTECT; do
  [ "$T" = "$B" ] && die "refusing: '$TARGET' is protected. Folds go into integration branches only."
done

SLUG="$(cd "$REPO" && gh repo view --json nameWithOwner --jq .nameWithOwner)" || die "gh cannot see this repo"
G fetch -q origin "$TARGET" || die "cannot fetch origin/$TARGET"
BASE="$(G rev-parse "origin/$TARGET")"
echo "target  $TARGET @ ${BASE:0:9}   repo $SLUG   mode: $([ $APPLY = 1 ] && echo APPLY || echo dry-run)"

TARGET_PREFIXES=""
if [ -n "$MIG_DIR" ]; then
  TARGET_PREFIXES="$(G ls-tree --name-only "origin/$TARGET" "$MIG_DIR/" | sed -n 's#.*/\([0-9][0-9]*\)_[^/]*\.sql$#\1#p' | sort -u)"
fi
SEEN_NEW=""   # lines "prefix PR file" added by earlier PRs in this fold

TIP="$BASE"; STATUS=0; APPLIED=0
printf '%-6s %-40s %-8s %s\n' "PR" "head" "state" "result"
for N in $PRS; do
  META="$(gh pr view "$N" --repo "$SLUG" --json headRefName,state --jq '[.headRefName,.state]|@tsv')" \
    || die "gh pr view $N failed"
  HEAD_REF="$(printf '%s' "$META" | cut -f1)"; STATE="$(printf '%s' "$META" | cut -f2)"
  G fetch -q origin "refs/pull/$N/head" || die "cannot fetch PR #$N"
  HEAD_SHA="$(G rev-parse FETCH_HEAD)"
  NOTE=""
  [ "$STATE" = "OPEN" ] || NOTE="$NOTE [state $STATE]"
  if G merge-base --is-ancestor "$HEAD_SHA" "$TIP"; then
    printf '%-6s %-40s %-8s %s\n' "#$N" "$HEAD_REF" "$STATE" "already contained (${HEAD_SHA:0:9})$NOTE"; continue
  fi

  FILES="$(G diff --name-only "$(G merge-base "$TIP" "$HEAD_SHA")" "$HEAD_SHA")"
  AREAS="$(printf '%s\n' "$FILES" | awk -F/ 'NF>2{print $1"/"$2; next} {print $1}' | sort -u | tr '\n' ' ')"

  if [ -n "$MIG_DIR" ]; then
    printf '%s\n' "$FILES" | grep -q "^$MIG_DIR/" && NOTE="$NOTE [migrations]"
    for F in $(G diff --name-only --diff-filter=A "$(G merge-base "origin/$TARGET" "$HEAD_SHA")" "$HEAD_SHA" -- "$MIG_DIR/" | grep -E '/[0-9]+_[^/]*\.sql$' || true); do
      P="$(basename "$F" | sed 's/_.*//')"
      if printf '%s\n' "$TARGET_PREFIXES" | grep -qx "$P" && ! G cat-file -e "origin/$TARGET:$F" 2>/dev/null; then
        NOTE="$NOTE [MIGRATION PREFIX $P ALREADY ON TARGET: $(basename "$F")]"; STATUS=$((STATUS | 2))
      fi
      CLASH="$(printf '%s\n' "$SEEN_NEW" | awk -v p="$P" -v f="$F" '$1==p && $3!=f {print "#"$2}' | head -1)"
      [ -n "$CLASH" ] && { NOTE="$NOTE [MIGRATION PREFIX $P ALSO IN $CLASH]"; STATUS=$((STATUS | 2)); }
      SEEN_NEW="$SEEN_NEW
$P $N $F"
    done
  fi

  if [ $APPLY = 0 ]; then
    # Predict against the running tip: merge-tree writes no refs and touches no checkout.
    if OUT="$(G merge-tree --write-tree --name-only --no-messages "$TIP" "$HEAD_SHA" 2>/dev/null)"; then
      TIP="$(G commit-tree "$(printf '%s\n' "$OUT" | head -1)" -p "$TIP" -p "$HEAD_SHA" -m sim)"
      printf '%-6s %-40s %-8s %s\n' "#$N" "$HEAD_REF" "$STATE" "clean  areas: $AREAS$NOTE"
    else
      CONFL="$(printf '%s\n' "$OUT" | tail -n +2 | grep -v '^$' | tr '\n' ' ')"
      printf '%-6s %-40s %-8s %s\n' "#$N" "$HEAD_REF" "$STATE" "CONFLICT in: $CONFL areas: $AREAS$NOTE"
      STATUS=$((STATUS | 1))
    fi
    continue
  fi

  # APPLY: one detached worktree at the integration tip; never a shared checkout.
  if [ -z "$WT" ]; then WT="$(dirname "$REPO")/$(basename "$REPO")-fold-$(printf '%s' "$T" | tr '/.' '--')"; fi
  if [ ! -d "$WT" ]; then
    G worktree add -q --detach "$WT" "$BASE"
    echo "worktree $WT (detached at ${BASE:0:9})"
  fi
  [ -z "$(git -C "$WT" status --porcelain)" ] || die "$WT is dirty: resolve or clean it first"
  [ "$(git -C "$WT" rev-parse --abbrev-ref HEAD)" = HEAD ] || die "$WT is on a branch, not a detached fold worktree"
  git -C "$WT" merge-base --is-ancestor "$BASE" HEAD || die "$WT does not contain $TARGET's tip ${BASE:0:9}: stale fold worktree"
  if git -C "$WT" merge --no-ff --no-edit -m "merge: #$N $HEAD_REF into $TARGET" "$HEAD_SHA" >/dev/null 2>&1; then
    TIP="$(git -C "$WT" rev-parse HEAD)"; APPLIED=1
    printf '%-6s %-40s %-8s %s\n' "#$N" "$HEAD_REF" "$STATE" "merged ${TIP:0:9}  areas: $AREAS$NOTE"
  else
    printf '%-6s %-40s %-8s %s\n' "#$N" "$HEAD_REF" "$STATE" "CONFLICT: stopped. Resolve in $WT, then: git -C $WT commit --no-edit"
    git -C "$WT" diff --name-only --diff-filter=U | sed 's/^/        U /'
    echo "rerun with the remaining PRs after committing the resolution."
    exit 1
  fi
done

if [ $APPLY = 1 ] && [ $APPLIED = 1 ]; then
  echo
  echo "head $(git -C "$WT" rev-parse --short HEAD) in $WT. Run the gates, then push yourself:"
  echo "  git -C $WT fetch origin $TARGET && git -C $WT merge-base --is-ancestor origin/$TARGET HEAD && git -C $WT push $PUSH_REMOTE HEAD:$TARGET"
fi
if [ $((STATUS & 2)) -ne 0 ]; then echo "migration prefix collision(s) above: renumber before pushing."; fi
exit $STATUS
