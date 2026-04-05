#!/bin/bash
# jware-task-counts.sh — Compute task counts from issue files
# Usage: jware-task-counts.sh <project-dir>
# Output: JSON with completed, inProgress, inReview, inQA, blocked, decisionsNeeded, total, progressPct

set -euo pipefail

PROJECT_DIR="${1:-}"
[ -z "$PROJECT_DIR" ] && { echo '{"error":"Usage: jware-task-counts.sh <project-dir>"}'; exit 2; }

ISSUES_DIR="$PROJECT_DIR/.jware/issues/issues"

if [ ! -d "$ISSUES_DIR" ]; then
  echo '{"completed":0,"inProgress":0,"inReview":0,"inQA":0,"blocked":0,"decisionsNeeded":0,"total":0,"progressPct":0}'
  exit 0
fi

# Count issues matching no files
shopt -s nullglob
FILES=("$ISSUES_DIR"/*.json)
shopt -u nullglob

if [ ${#FILES[@]} -eq 0 ]; then
  echo '{"completed":0,"inProgress":0,"inReview":0,"inQA":0,"blocked":0,"decisionsNeeded":0,"total":0,"progressPct":0}'
  exit 0
fi

# Process all issues in a single jq pass
cat "${FILES[@]}" | jq -s '
  {
    completed: [.[] | select(.status == "done" or .status == "closed" or (.labels // [] | index("done")))] | length,
    inProgress: [.[] | select(.status == "in_progress")] | length,
    inReview: [.[] | select((.labels // []) | index("in-review"))] | length,
    inQA: [.[] | select((.labels // []) | index("in-qa"))] | length,
    blocked: [.[] | select((.labels // []) | index("blocked"))] | length,
    decisionsNeeded: [.[] | select(
      ((.labels // []) | index("decision-needed")) and
      (.userVote.verdict == null)
    )] | length,
    total: length
  } | .progressPct = (if .total > 0 then ((.completed * 100 / .total) | floor) else 0 end)
'
