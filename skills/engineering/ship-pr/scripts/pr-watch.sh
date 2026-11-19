#!/usr/bin/env bash
# pr-watch.sh: wait on a pull request and print one line per real event. Never sleeps blind,
# never posts, never merges. Run it in the background (Claude Code: the Monitor tool) and act
# only when it prints or exits.
#
#   pr-watch.sh <pr> [--until green|change] [--interval 60] [--timeout 3600] [--repo owner/name]
#              [--ignore vercel,github-actions,netlify,codecov,dependabot]  (comment authors to skip,
#              prefix match; your own gh login is always skipped)
#              [--no-checks-after 300]  (seconds with zero checks before a repo counts as having no CI)
#
# Events: new head commit, a check finishing or failing on the current head, a new review, a new
# comment or inline comment, the branch going BEHIND or DIRTY, the PR closing or merging.
# --until green  (default) exit 0 when every check on the latest head passed on two polls in a row
#                and no change is requested; exit 1 as soon as something needs you.
# --until change exit 0 at the first event after the baseline.
# Exit: 0 green / merged / changed, 1 needs you (failed check, change request, new comment,
# conflict, PR closed unmerged), 2 bad input, 3 timeout. State survives a restart, so an event is
# reported once: ${XDG_STATE_HOME:-~/.local/state}/founderstack/pr-watch/.
set -euo pipefail

PR=""; UNTIL=green; INTERVAL=60; TIMEOUT=3600; REPO=""; NOCHECKS=300
IGNORE="vercel,github-actions,netlify,codecov,dependabot"
while [ $# -gt 0 ]; do
  case "$1" in
    --until) UNTIL="${2:-}"; shift 2 ;;
    --interval) INTERVAL="${2:-}"; shift 2 ;;
    --timeout) TIMEOUT="${2:-}"; shift 2 ;;
    --repo) REPO="${2:-}"; shift 2 ;;
    --ignore) IGNORE="${2:-}"; shift 2 ;;
    --no-checks-after) NOCHECKS="${2:-}"; shift 2 ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    *) PR="${1#\#}"; shift ;;
  esac
done
bad() { echo "pr-watch: $*" >&2; exit 2; }
case "$PR" in ''|*[!0-9]*) bad "usage: pr-watch.sh <pr-number> [--until green|change]" ;; esac
case "$UNTIL" in green|change) ;; *) bad "--until must be green or change" ;; esac
for n in "$INTERVAL" "$TIMEOUT" "$NOCHECKS"; do case "$n" in ''|*[!0-9]*) bad "numbers only for --interval/--timeout/--no-checks-after" ;; esac; done
REPO="${REPO:-$(gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null)}" || bad "gh cannot see the repo"
[ -n "$REPO" ] || bad "gh cannot see the repo"

# Comment authors to skip. Only letters, digits, - and _ survive, because the pattern is spliced
# into jq. Empty items are dropped: an empty alternative would match every login.
ALTS="$(printf '%s' "$IGNORE" | tr -cd 'A-Za-z0-9,_-' | tr ',' '\n' | sed '/^$/d' | paste -sd'|' -)"
ME="$(gh api user --jq .login 2>/dev/null | tr -cd 'A-Za-z0-9_-' || true)"
[ -n "$ME" ] && ALTS="${ALTS:+$ALTS|}$ME\$"
IGN_RE="^(${ALTS:-\$^})"

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/founderstack/pr-watch"
mkdir -p "$STATE_DIR"
STATE="$STATE_DIR/$(printf '%s' "$REPO" | tr '/' '_')-$PR"

say() { printf '%s  #%s  %s\n' "$(date '+%H:%M:%S')" "$PR" "$*"; }

snapshot() {
  # One "|"-separated line of facts. "|" is not whitespace, so empty fields cannot collapse.
  gh pr view "$PR" --repo "$REPO" --json state,headRefOid,mergeStateStatus,reviewDecision,statusCheckRollup,reviews,comments --jq '
    def done: (.status // "COMPLETED") == "COMPLETED" and ((.state // "SUCCESS") | IN("PENDING","EXPECTED") | not);
    def bad: ((.conclusion // "") | IN("FAILURE","TIMED_OUT","CANCELLED","ACTION_REQUIRED","STARTUP_FAILURE"))
             or ((.state // "") | IN("FAILURE","ERROR"));
    [ .state, .headRefOid[0:9], (.mergeStateStatus // "UNKNOWN"),
      ((.reviewDecision // "") | if . == "" then "NONE" else . end),
      ([.statusCheckRollup[] | select(done | not)] | length),
      ([.statusCheckRollup[] | select(bad) | (.name // .context) | gsub("[|,]"; "/")] | join(",") | if . == "" then "none" else . end),
      ([.statusCheckRollup[]] | length),
      (.reviews | length),
      ([.comments[] | select(.author.login | test("'"$IGN_RE"'"; "i") | not)] | length)
    ] | map(tostring) | join("|")' 2>/dev/null
}
inline_count() {
  # Prints the count, or nothing if gh failed (the caller keeps the previous count).
  gh api "repos/$REPO/pulls/$PR/comments" --paginate \
    --jq "[.[] | select(.user.login | test(\"$IGN_RE\"; \"i\") | not)] | length" 2>/dev/null \
    | awk '{s+=$1} END{if (NR) print s+0}'
}

START=$(date +%s); BACKOFF=$INTERVAL; PREV="$(cat "$STATE" 2>/dev/null || true)"; GREEN=0; ZERO_SINCE=""
say "watching $REPO until $UNTIL (every ${INTERVAL}s, timeout ${TIMEOUT}s)"
while :; do
  [ $(( $(date +%s) - START )) -ge "$TIMEOUT" ] && { say "timeout"; exit 3; }
  if ! SNAP="$(snapshot)" || [ -z "$SNAP" ]; then
    BACKOFF=$(( BACKOFF * 2 > 300 ? 300 : BACKOFF * 2 )); say "gh failed, retrying in ${BACKOFF}s"; sleep "$BACKOFF"; continue
  fi
  BACKOFF=$INTERVAL
  P_INL="$(printf '%s' "$PREV" | cut -d'|' -f10)"
  INL="$(inline_count || true)"; SNAP="$SNAP|${INL:-${P_INL:-0}}"
  IFS='|' read -r ST SHA MERGE DECISION PENDING FAILED TOTAL REVIEWS COMMENTS INLINE <<<"$SNAP"

  NEED=0; EVENT=0
  if [ -z "$PREV" ]; then
    # First run: what is already there is the baseline, not news. ship-pr reads it before waiting.
    say "baseline: head $SHA, $TOTAL check(s), $REVIEWS review(s), $COMMENTS comment(s), $INLINE inline, decision $DECISION"
    PREV="$SNAP"
    [ "$FAILED" != none ] && { say "FAILED on $SHA: $FAILED"; NEED=1; }
    [ "$DECISION" = CHANGES_REQUESTED ] && { say "changes requested"; NEED=1; }
    case "$MERGE" in BEHIND|DIRTY) say "branch is $MERGE"; NEED=1 ;; esac
  fi
  IFS='|' read -r P_ST P_SHA P_MERGE P_DECISION P_PENDING P_FAILED _ P_REVIEWS P_COMMENTS P_INLINE <<<"$PREV"
  # A failure on a new head is news even when it is the same check that failed before.
  [ "$SHA" != "$P_SHA" ] && P_FAILED=none
  if [ "$SNAP" != "$PREV" ]; then
    [ "$ST" != "$P_ST" ] && { say "state $ST"; EVENT=1; }
    [ "$SHA" != "$P_SHA" ] && { say "head $SHA"; EVENT=1; GREEN=0; }
    [ "$PENDING" != "$P_PENDING" ] && [ "$PENDING" = 0 ] && [ "$TOTAL" -gt 0 ] && { say "checks finished ($TOTAL) on $SHA"; EVENT=1; }
    [ "$FAILED" != "$P_FAILED" ] && [ "$FAILED" != none ] && { say "FAILED on $SHA: $FAILED"; EVENT=1; NEED=1; }
    [ "$DECISION" != "$P_DECISION" ] && { say "review decision $DECISION"; EVENT=1; [ "$DECISION" = CHANGES_REQUESTED ] && NEED=1; }
    [ "$REVIEWS" -gt "$P_REVIEWS" ] && { say "new review(s): $((REVIEWS - P_REVIEWS))"; EVENT=1; NEED=1; }
    [ "$COMMENTS" -gt "$P_COMMENTS" ] && { say "new comment(s): $((COMMENTS - P_COMMENTS))"; EVENT=1; NEED=1; }
    [ "$INLINE" -gt "$P_INLINE" ] && { say "new inline comment(s): $((INLINE - P_INLINE))"; EVENT=1; NEED=1; }
    [ "$MERGE" != "$P_MERGE" ] && case "$MERGE" in BEHIND|DIRTY) say "branch is $MERGE"; EVENT=1; NEED=1 ;; esac
  fi
  printf '%s\n' "$SNAP" > "$STATE"; PREV="$SNAP"

  case "$ST" in
    MERGED) say "PR is merged"; exit 0 ;;
    CLOSED) say "PR was closed without merging"; exit 1 ;;
  esac
  if [ "$UNTIL" = change ] && [ $EVENT = 1 ]; then exit 0; fi
  if [ "$UNTIL" = green ]; then
    [ $NEED = 1 ] && { say "needs you"; exit 1; }
    if [ "$TOTAL" = 0 ]; then
      ZERO_SINCE="${ZERO_SINCE:-$(date +%s)}"
      if [ $(( $(date +%s) - ZERO_SINCE )) -ge "$NOCHECKS" ] && [ "$DECISION" != CHANGES_REQUESTED ]; then
        say "no checks reported in ${NOCHECKS}s: this repo seems to have no CI. Nothing to wait for on $SHA"; exit 0
      fi
    else
      ZERO_SINCE=""
      if [ "$PENDING" = 0 ] && [ "$FAILED" = none ] && [ "$DECISION" != CHANGES_REQUESTED ]; then
        # Two green polls in a row, so a slow check that registers late is not missed.
        GREEN=$((GREEN + 1)); [ $GREEN -ge 2 ] && { say "green on $SHA"; exit 0; }
      else
        GREEN=0
      fi
    fi
  fi
  sleep "$INTERVAL"
done
