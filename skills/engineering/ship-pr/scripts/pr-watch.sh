#!/usr/bin/env bash
# pr-watch.sh: wait on a pull request and print one line per real event. Never sleeps blind,
# never posts, never merges. Run it in the background (Claude Code: the Monitor tool) and act
# only when it prints or exits.
#
#   pr-watch.sh <pr> [--until green|change] [--interval 60] [--timeout 3600] [--repo owner/name]
#              [--ignore vercel,github-actions,netlify,codecov]  (comment authors to skip, prefix match)
#
# Events: new head commit, a check finishing, a new review, a new comment or inline comment,
# the branch going BEHIND or DIRTY, the PR closing or merging.
# --until green  (default) exit 0 when every check on the latest head passed and no change is
#                requested; exit 1 as soon as something needs you (a check failed, changes
#                requested, a new human or bot review comment, a conflict).
# --until change exit 0 at the first event.
# Exit: 0 done, 1 needs you, 2 bad input, 3 timeout. State survives a restart, so an event is
# reported once: ${XDG_STATE_HOME:-~/.local/state}/founderstack/pr-watch/.
set -euo pipefail

PR=""; UNTIL=green; INTERVAL=60; TIMEOUT=3600; REPO=""; IGNORE="vercel,github-actions,netlify,codecov,dependabot"
while [ $# -gt 0 ]; do
  case "$1" in
    --until) UNTIL="$2"; shift 2 ;;
    --interval) INTERVAL="$2"; shift 2 ;;
    --timeout) TIMEOUT="$2"; shift 2 ;;
    --repo) REPO="$2"; shift 2 ;;
    --ignore) IGNORE="$2"; shift 2 ;;
    -h|--help) sed -n '2,19p' "$0"; exit 0 ;;
    *) PR="${1#\#}"; shift ;;
  esac
done
case "$PR" in ''|*[!0-9]*) echo "usage: pr-watch.sh <pr-number> [--until green|change]" >&2; exit 2 ;; esac
case "$UNTIL" in green|change) ;; *) echo "--until must be green or change" >&2; exit 2 ;; esac
REPO="${REPO:-$(gh repo view --json nameWithOwner --jq .nameWithOwner)}" || { echo "gh cannot see the repo" >&2; exit 2; }

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/founderstack/pr-watch"
mkdir -p "$STATE_DIR"
STATE="$STATE_DIR/$(printf '%s' "$REPO" | tr '/' '_')-$PR"
IGN_RE="^($(printf '%s' "$IGNORE" | tr -cd 'A-Za-z0-9,_-' | sed 's/,/|/g'))"   # letters only: it is spliced into jq

say() { printf '%s  #%s  %s\n' "$(date '+%H:%M:%S')" "$PR" "$*"; }

snapshot() {
  # One line of facts; each poll is compared with the last one written to $STATE.
  gh pr view "$PR" --repo "$REPO" --json state,headRefOid,mergeStateStatus,reviewDecision,statusCheckRollup,reviews,comments --jq '
    def done: (.status // "COMPLETED") == "COMPLETED" and ((.state // "SUCCESS") | IN("PENDING","EXPECTED") | not);
    def bad: ((.conclusion // "") | IN("FAILURE","TIMED_OUT","CANCELLED","ACTION_REQUIRED","STARTUP_FAILURE"))
             or ((.state // "") | IN("FAILURE","ERROR"));
    [ .state, .headRefOid[0:9], (.mergeStateStatus // "UNKNOWN"), ((.reviewDecision // "") | if . == "" then "NONE" else . end),
      ([.statusCheckRollup[] | select(done | not)] | length),
      ([.statusCheckRollup[] | select(bad) | (.name // .context) | gsub("[|,]"; "/")] | join(",") | if . == "" then "none" else . end),
      ([.statusCheckRollup[]] | length),
      (.reviews | length),
      ([.comments[] | select(.author.login | test("'"$IGN_RE"'"; "i") | not)] | length)
    ] | map(tostring) | join("|")' 2>/dev/null || return 1
}
inline_count() {
  gh api "repos/$REPO/pulls/$PR/comments" --paginate --jq "[.[] | select(.user.login | test(\"$IGN_RE\"; \"i\") | not)] | length" 2>/dev/null \
    | awk '{s+=$1} END{print s+0}'
}

START=$(date +%s); BACKOFF=$INTERVAL; PREV="$(cat "$STATE" 2>/dev/null || true)"
say "watching $REPO until $UNTIL (every ${INTERVAL}s, timeout ${TIMEOUT}s)"
while :; do
  [ $(( $(date +%s) - START )) -ge "$TIMEOUT" ] && { say "timeout"; exit 3; }
  if ! SNAP="$(snapshot)"; then
    BACKOFF=$(( BACKOFF * 2 > 300 ? 300 : BACKOFF * 2 )); say "gh failed, retrying in ${BACKOFF}s"; sleep "$BACKOFF"; continue
  fi
  BACKOFF=$INTERVAL
  SNAP="$SNAP|$(inline_count)"
  # "|" is not whitespace, so empty fields cannot collapse and shift the columns.
  IFS='|' read -r ST SHA MERGE DECISION PENDING FAILED TOTAL REVIEWS COMMENTS INLINE <<<"$SNAP"
  IFS='|' read -r P_ST P_SHA P_MERGE P_DECISION P_PENDING P_FAILED _ P_REVIEWS P_COMMENTS P_INLINE <<<"${PREV:-x|x|x|x|x|none|x|0|0|0}"
  NEED=0; EVENT=0
  if [ -z "$PREV" ]; then
    # First run: what is already there is the baseline, not news. ship-pr reads it before waiting.
    say "baseline: $REVIEWS review(s), $COMMENTS comment(s), $INLINE inline comment(s)"
    P_REVIEWS=$REVIEWS; P_COMMENTS=$COMMENTS; P_INLINE=$INLINE
  fi
  if [ "$SNAP" != "$PREV" ]; then
    [ "$ST" != "$P_ST" ] && { say "state $ST"; EVENT=1; }
    [ "$SHA" != "$P_SHA" ] && { say "head $SHA"; EVENT=1; }
    [ "$PENDING" != "$P_PENDING" ] && [ "$PENDING" = 0 ] && [ "$TOTAL" -gt 0 ] && { say "checks finished ($TOTAL)"; EVENT=1; }
    [ "$FAILED" != "$P_FAILED" ] && [ "$FAILED" != none ] && { say "FAILED: $FAILED"; EVENT=1; NEED=1; }
    [ "$DECISION" != "$P_DECISION" ] && { say "review decision $DECISION"; EVENT=1; [ "$DECISION" = CHANGES_REQUESTED ] && NEED=1; }
    [ "$REVIEWS" -gt "${P_REVIEWS:-0}" ] 2>/dev/null && { say "new review(s): $((REVIEWS - P_REVIEWS))"; EVENT=1; NEED=1; }
    [ "$COMMENTS" -gt "${P_COMMENTS:-0}" ] 2>/dev/null && { say "new comment(s): $((COMMENTS - P_COMMENTS))"; EVENT=1; NEED=1; }
    [ "$INLINE" -gt "${P_INLINE:-0}" ] 2>/dev/null && { say "new inline comment(s): $((INLINE - P_INLINE))"; EVENT=1; NEED=1; }
    [ "$MERGE" != "$P_MERGE" ] && case "$MERGE" in BEHIND|DIRTY) say "branch is $MERGE"; EVENT=1; NEED=1 ;; esac
    printf '%s\n' "$SNAP" > "$STATE"; PREV="$SNAP"
  fi
  case "$ST" in MERGED|CLOSED) say "PR is $ST"; exit 0 ;; esac
  if [ "$UNTIL" = change ] && [ $EVENT = 1 ]; then exit 0; fi
  if [ "$UNTIL" = green ]; then
    [ $NEED = 1 ] && { say "needs you"; exit 1; }
    if [ "$TOTAL" -gt 0 ] && [ "$PENDING" = 0 ] && [ "$FAILED" = none ] && [ "$DECISION" != CHANGES_REQUESTED ]; then
      say "green on $SHA"; exit 0
    fi
  fi
  [ $(( $(date +%s) - START )) -ge "$TIMEOUT" ] && { say "timeout"; exit 3; }
  sleep "$INTERVAL"
done
