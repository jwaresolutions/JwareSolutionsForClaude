#!/bin/bash
# jware-issue.sh — Unified CLI for issue tracker operations
# Usage: jware-issue.sh <command> <project-dir> [args...]
# All issue data lives at <project-dir>/.jware/issues/

set -euo pipefail

CMD="${1:-}"
PROJECT_DIR="${2:-}"
ISSUES_ROOT=""

die() { echo "ERROR: $*" >&2; exit 2; }
biz_err() { echo "ERROR: $*" >&2; exit 1; }

# Resolve issues root
setup_root() {
  [ -z "$PROJECT_DIR" ] && die "Usage: jware-issue.sh <command> <project-dir> [args...]"
  ISSUES_ROOT="$PROJECT_DIR/.jware/issues"
}

# Atomic write: temp file + mv
atomic_write() {
  local target="$1" content="$2"
  local dir; dir=$(dirname "$target")
  local tmp; tmp=$(mktemp "$dir/XXXXXX.tmp")
  echo "$content" > "$tmp"
  mv "$tmp" "$target"
}

# Read config
read_config() {
  [ -f "$ISSUES_ROOT/config.json" ] || die "No config.json at $ISSUES_ROOT. Run 'init' first."
  cat "$ISSUES_ROOT/config.json"
}

# Zero-pad ID to 3 digits
pad_id() { printf "%03d" "$1"; }

# Get ISO 8601 UTC timestamp
now_ts() { date -u +%Y-%m-%dT%H:%M:%SZ; }

# ============================================================
# INIT
# ============================================================
cmd_init() {
  local name="${3:-$(basename "$PROJECT_DIR")}"
  mkdir -p "$ISSUES_ROOT/issues" "$ISSUES_ROOT/projects" "$ISSUES_ROOT/assets"
  if [ ! -f "$ISSUES_ROOT/config.json" ]; then
    atomic_write "$ISSUES_ROOT/config.json" "$(jq -n \
      --arg name "$name" \
      '{name: $name, nextIssueId: 1, nextProjectId: 1, reviewers: ["PM", "Dev Lead", "Security"]}')"
    echo "INITIALIZED: $ISSUES_ROOT (name=$name)"
  else
    echo "EXISTS: $ISSUES_ROOT already initialized"
  fi
}

# ============================================================
# CREATE ISSUE
# ============================================================
cmd_create() {
  shift 2 # remove cmd and project-dir
  local title="" desc="" priority="medium" labels="" project_id="null" cycle="null" status="open"
  while [ $# -gt 0 ]; do
    case "$1" in
      --title) title="$2"; shift 2 ;;
      --desc) desc="$2"; shift 2 ;;
      --priority) priority="$2"; shift 2 ;;
      --labels) labels="$2"; shift 2 ;;
      --project-id) project_id="$2"; shift 2 ;;
      --cycle) cycle="$2"; shift 2 ;;
      --status) status="$2"; shift 2 ;;
      *) die "Unknown arg: $1" ;;
    esac
  done
  [ -z "$title" ] && die "create requires --title"

  local config; config=$(read_config)
  local new_id; new_id=$(echo "$config" | jq -r '.nextIssueId')
  local padded; padded=$(pad_id "$new_id")
  local ts; ts=$(now_ts)

  # Build reviewers object
  local reviewers_obj; reviewers_obj=$(echo "$config" | jq '.reviewers | map({key: ., value: {verdict: null, notes: ""}}) | from_entries')

  # Build labels array
  local labels_arr="[]"
  if [ -n "$labels" ]; then
    labels_arr=$(echo "$labels" | tr ',' '\n' | jq -R . | jq -s .)
  fi

  # Build issue JSON
  local issue; issue=$(jq -n \
    --argjson id "$new_id" \
    --arg title "$title" \
    --arg desc "$desc" \
    --arg status "$status" \
    --arg priority "$priority" \
    --argjson labels "$labels_arr" \
    --argjson projectId "$project_id" \
    --argjson cycle "$cycle" \
    --argjson reviews "$reviewers_obj" \
    --arg ts "$ts" \
    '{
      id: $id,
      title: $title,
      description: $desc,
      status: $status,
      priority: $priority,
      labels: $labels,
      projectId: $projectId,
      cycle: $cycle,
      personas: [],
      files: [],
      blockedBy: [],
      reviews: $reviews,
      userVote: {verdict: null, notes: ""},
      createdAt: $ts,
      updatedAt: $ts
    }')

  atomic_write "$ISSUES_ROOT/issues/$padded.json" "$issue"

  # Increment nextIssueId
  local new_config; new_config=$(echo "$config" | jq --argjson nid "$((new_id + 1))" '.nextIssueId = $nid')
  atomic_write "$ISSUES_ROOT/config.json" "$new_config"

  echo "CREATED: #$new_id \"$title\""
}

# ============================================================
# GET ISSUE
# ============================================================
cmd_get() {
  local issue_id="${3:-}"
  [ -z "$issue_id" ] && die "get requires <issue-id>"
  local padded; padded=$(pad_id "$issue_id")
  local file="$ISSUES_ROOT/issues/$padded.json"
  [ -f "$file" ] || biz_err "Issue #$issue_id does not exist."
  jq . "$file"
}

# ============================================================
# LIST ISSUES
# ============================================================
cmd_list() {
  shift 2
  local filter_status="" filter_priority="" filter_label="" filter_project="" filter_cycle="" format="table"
  while [ $# -gt 0 ]; do
    case "$1" in
      --status) filter_status="$2"; shift 2 ;;
      --priority) filter_priority="$2"; shift 2 ;;
      --label) filter_label="$2"; shift 2 ;;
      --project-id) filter_project="$2"; shift 2 ;;
      --cycle) filter_cycle="$2"; shift 2 ;;
      --format) format="$2"; shift 2 ;;
      *) die "Unknown arg: $1" ;;
    esac
  done

  local issues_dir="$ISSUES_ROOT/issues"
  [ -d "$issues_dir" ] || die "No issues directory"

  # Collect all issues into array
  local all="[]"
  for f in "$issues_dir"/*.json; do
    [ -f "$f" ] || continue
    all=$(echo "$all" | jq --slurpfile issue "$f" '. + $issue')
  done

  # Apply filters
  local filtered="$all"
  [ -n "$filter_status" ] && filtered=$(echo "$filtered" | jq --arg s "$filter_status" '[.[] | select(.status == $s)]')
  [ -n "$filter_priority" ] && filtered=$(echo "$filtered" | jq --arg p "$filter_priority" '[.[] | select(.priority == $p)]')
  [ -n "$filter_label" ] && filtered=$(echo "$filtered" | jq --arg l "$filter_label" '[.[] | select(.labels | index($l))]')
  [ -n "$filter_project" ] && filtered=$(echo "$filtered" | jq --argjson p "$filter_project" '[.[] | select(.projectId == $p)]')
  [ -n "$filter_cycle" ] && filtered=$(echo "$filtered" | jq --argjson c "$filter_cycle" '[.[] | select(.cycle == $c)]')

  # Sort by id
  filtered=$(echo "$filtered" | jq 'sort_by(.id)')

  if [ "$format" = "json" ]; then
    echo "$filtered" | jq .
  else
    local count; count=$(echo "$filtered" | jq 'length')
    if [ "$count" -eq 0 ]; then
      echo "No issues found."
      return
    fi
    printf "%-5s %-13s %-8s %s\n" "ID" "STATUS" "PRI" "TITLE"
    printf "%-5s %-13s %-8s %s\n" "---" "------" "---" "-----"
    echo "$filtered" | jq -r '.[] | "#\(.id)\t\(.status)\t\(.priority)\t\(.title)"' | while IFS=$'\t' read -r id status pri title; do
      printf "%-5s %-13s %-8s %s\n" "$id" "$status" "$pri" "$title"
    done
  fi
}

# ============================================================
# UPDATE ISSUE
# ============================================================
cmd_update() {
  local issue_id="${3:-}"
  [ -z "$issue_id" ] && die "update requires <issue-id>"
  local padded; padded=$(pad_id "$issue_id")
  local file="$ISSUES_ROOT/issues/$padded.json"
  [ -f "$file" ] || biz_err "Issue #$issue_id does not exist."

  shift 3
  local issue; issue=$(cat "$file")
  local changed=false

  while [ $# -gt 0 ]; do
    case "$1" in
      --title) issue=$(echo "$issue" | jq --arg v "$2" '.title = $v'); changed=true; shift 2 ;;
      --desc) issue=$(echo "$issue" | jq --arg v "$2" '.description = $v'); changed=true; shift 2 ;;
      --status) issue=$(echo "$issue" | jq --arg v "$2" '.status = $v'); changed=true; shift 2 ;;
      --priority) issue=$(echo "$issue" | jq --arg v "$2" '.priority = $v'); changed=true; shift 2 ;;
      --labels)
        local arr; arr=$(echo "$2" | tr ',' '\n' | jq -R . | jq -s .)
        issue=$(echo "$issue" | jq --argjson v "$arr" '.labels = $v'); changed=true; shift 2 ;;
      --add-label)
        issue=$(echo "$issue" | jq --arg v "$2" '.labels = (.labels + [$v] | unique)'); changed=true; shift 2 ;;
      --remove-label)
        issue=$(echo "$issue" | jq --arg v "$2" '.labels = [.labels[] | select(. != $v)]'); changed=true; shift 2 ;;
      --cycle) issue=$(echo "$issue" | jq --argjson v "$2" '.cycle = $v'); changed=true; shift 2 ;;
      --project-id) issue=$(echo "$issue" | jq --argjson v "$2" '.projectId = $v'); changed=true; shift 2 ;;
      --files)
        local farr; farr=$(echo "$2" | tr ',' '\n' | jq -R . | jq -s .)
        issue=$(echo "$issue" | jq --argjson v "$farr" '.files = $v'); changed=true; shift 2 ;;
      --blocked-by)
        local barr; barr=$(echo "$2" | tr ',' '\n' | jq -R 'tonumber' | jq -s .)
        # Cycle detection
        for blocker_id in $(echo "$barr" | jq -r '.[]'); do
          check_cycle "$issue_id" "$blocker_id"
        done
        issue=$(echo "$issue" | jq --argjson v "$barr" '.blockedBy = $v'); changed=true; shift 2 ;;
      --personas)
        local parr; parr=$(echo "$2" | tr ',' '\n' | jq -R . | jq -s .)
        issue=$(echo "$issue" | jq --argjson v "$parr" '.personas = $v'); changed=true; shift 2 ;;
      *) die "Unknown arg: $1" ;;
    esac
  done

  if [ "$changed" = true ]; then
    issue=$(echo "$issue" | jq --arg ts "$(now_ts)" '.updatedAt = $ts')
    atomic_write "$file" "$issue"
    echo "UPDATED: #$issue_id"
  else
    echo "NO-CHANGE: #$issue_id (no fields specified)"
  fi
}

# ============================================================
# DELETE ISSUE
# ============================================================
cmd_delete() {
  local issue_id="${3:-}"
  [ -z "$issue_id" ] && die "delete requires <issue-id>"
  local padded; padded=$(pad_id "$issue_id")
  local file="$ISSUES_ROOT/issues/$padded.json"
  [ -f "$file" ] || biz_err "Issue #$issue_id does not exist."

  rm "$file"

  # Clean blockedBy references in all other issues
  for f in "$ISSUES_ROOT/issues"/*.json; do
    [ -f "$f" ] || continue
    local has_ref; has_ref=$(jq --argjson id "$issue_id" '.blockedBy | index($id) // -1' "$f")
    if [ "$has_ref" -ge 0 ]; then
      local updated; updated=$(jq --argjson id "$issue_id" --arg ts "$(now_ts)" \
        '.blockedBy = [.blockedBy[] | select(. != $id)] | .updatedAt = $ts' "$f")
      atomic_write "$f" "$updated"
    fi
  done

  # Remove assets
  [ -d "$ISSUES_ROOT/assets/$issue_id" ] && rm -rf "$ISSUES_ROOT/assets/$issue_id"

  echo "DELETED: #$issue_id"
}

# ============================================================
# REVIEW
# ============================================================
cmd_review() {
  local issue_id="${3:-}" reviewer="${4:-}" verdict="${5:-}" notes="${6:-}"
  [ -z "$issue_id" ] && die "review requires <issue-id> <reviewer> <verdict> [notes]"
  [ -z "$reviewer" ] && die "review requires <reviewer>"
  [ -z "$verdict" ] && die "review requires <verdict> (approve|defer|reject)"

  case "$verdict" in
    approve|defer|reject) ;;
    *) die "verdict must be: approve, defer, or reject" ;;
  esac

  local padded; padded=$(pad_id "$issue_id")
  local file="$ISSUES_ROOT/issues/$padded.json"
  [ -f "$file" ] || biz_err "Issue #$issue_id does not exist."

  local issue; issue=$(jq \
    --arg r "$reviewer" --arg v "$verdict" --arg n "${notes:-}" --arg ts "$(now_ts)" \
    '.reviews[$r] = {verdict: $v, notes: $n} | .updatedAt = $ts' "$file")
  atomic_write "$file" "$issue"
  echo "REVIEWED: #$issue_id by $reviewer = $verdict"
}

# ============================================================
# VOTE
# ============================================================
cmd_vote() {
  local issue_id="${3:-}" verdict="${4:-}" notes="${5:-}"
  [ -z "$issue_id" ] && die "vote requires <issue-id> <verdict> [notes]"
  [ -z "$verdict" ] && die "vote requires <verdict> (approve|defer|reject)"

  case "$verdict" in
    approve|defer|reject) ;;
    *) die "verdict must be: approve, defer, or reject" ;;
  esac

  local padded; padded=$(pad_id "$issue_id")
  local file="$ISSUES_ROOT/issues/$padded.json"
  [ -f "$file" ] || biz_err "Issue #$issue_id does not exist."

  local issue; issue=$(jq \
    --arg v "$verdict" --arg n "${notes:-}" --arg ts "$(now_ts)" \
    '.userVote = {verdict: $v, notes: $n} | .updatedAt = $ts' "$file")
  atomic_write "$file" "$issue"
  echo "VOTED: #$issue_id = $verdict"
}

# ============================================================
# QUICK WINS
# ============================================================
cmd_quickwins() {
  local config; config=$(read_config)
  local issues_dir="$ISSUES_ROOT/issues"

  # Use jq to check all reviewers approved (handles names with spaces like "Dev Lead")
  local reviewer_arr; reviewer_arr=$(echo "$config" | jq -c '.reviewers')

  local wins="[]"
  for f in "$issues_dir"/*.json; do
    [ -f "$f" ] || continue
    local issue; issue=$(cat "$f")
    local status; status=$(echo "$issue" | jq -r '.status')
    local priority; priority=$(echo "$issue" | jq -r '.priority')

    # Skip done/closed or low priority
    [ "$status" = "done" ] || [ "$status" = "closed" ] && continue
    [ "$priority" = "low" ] && continue

    # Check all reviewers approved (done entirely in jq to avoid word-splitting)
    local all_approved; all_approved=$(echo "$issue" | jq --argjson revs "$reviewer_arr" \
      '[$revs[] as $r | .reviews[$r].verdict] | all(. == "approve")')

    if [ "$all_approved" = "true" ]; then
      wins=$(echo "$wins" | jq --slurpfile i <(echo "$issue") '. + $i')
    fi
  done

  local count; count=$(echo "$wins" | jq 'length')
  if [ "$count" -eq 0 ]; then
    echo "No quick wins found."
    return
  fi

  echo "QUICK WINS ($count):"
  printf "%-5s %-8s %s\n" "ID" "PRI" "TITLE"
  printf "%-5s %-8s %s\n" "---" "---" "-----"
  echo "$wins" | jq -r '.[] | "#\(.id)\t\(.priority)\t\(.title)"' | while IFS=$'\t' read -r id pri title; do
    printf "%-5s %-8s %s\n" "$id" "$pri" "$title"
  done
}

# ============================================================
# CYCLE DETECTION (DFS)
# ============================================================
check_cycle() {
  local target_id="$1" blocker_id="$2"
  # DFS from blocker_id following blockedBy edges; if we reach target_id, there's a cycle
  local visited=""
  local stack="$blocker_id"

  while [ -n "$stack" ]; do
    local current; current=$(echo "$stack" | cut -d' ' -f1)
    stack=$(echo "$stack" | cut -d' ' -f2- | sed 's/^ *//')
    [ "$current" = "$stack" ] && stack=""

    # If we reached the target, cycle detected
    if [ "$current" = "$target_id" ]; then
      biz_err "Cycle detected: #$target_id → #$blocker_id → ... → #$target_id"
    fi

    # Skip if visited
    echo "$visited" | grep -qw "$current" && continue
    visited="$visited $current"

    # Get blockedBy for current
    local padded; padded=$(pad_id "$current")
    local file="$ISSUES_ROOT/issues/$padded.json"
    [ -f "$file" ] || continue

    local blockers; blockers=$(jq -r '.blockedBy[]' "$file" 2>/dev/null)
    for b in $blockers; do
      stack="$b $stack"
    done
  done
}

cmd_check_cycle() {
  local issue_id="${3:-}" proposed="${4:-}"
  [ -z "$issue_id" ] || [ -z "$proposed" ] && die "check-cycle requires <issue-id> <proposed-blockers>"

  for blocker_id in $(echo "$proposed" | tr ',' ' '); do
    check_cycle "$issue_id" "$blocker_id"
  done
  echo "OK: No cycles detected"
}

# ============================================================
# PROJECT CRUD
# ============================================================
cmd_project_create() {
  shift 2
  local name="" desc=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --name) name="$2"; shift 2 ;;
      --desc) desc="$2"; shift 2 ;;
      *) die "Unknown arg: $1" ;;
    esac
  done
  [ -z "$name" ] && die "project-create requires --name"

  local config; config=$(read_config)
  local new_id; new_id=$(echo "$config" | jq -r '.nextProjectId')
  local padded; padded=$(pad_id "$new_id")
  local ts; ts=$(now_ts)

  local project; project=$(jq -n \
    --argjson id "$new_id" --arg name "$name" --arg desc "$desc" --arg ts "$ts" \
    '{id: $id, name: $name, description: $desc, status: "active", createdAt: $ts}')

  mkdir -p "$ISSUES_ROOT/projects"
  atomic_write "$ISSUES_ROOT/projects/$padded.json" "$project"

  local new_config; new_config=$(echo "$config" | jq --argjson nid "$((new_id + 1))" '.nextProjectId = $nid')
  atomic_write "$ISSUES_ROOT/config.json" "$new_config"

  echo "PROJECT-CREATED: #$new_id \"$name\""
}

cmd_project_list() {
  local projects_dir="$ISSUES_ROOT/projects"
  [ -d "$projects_dir" ] || { echo "No projects."; return; }

  printf "%-5s %-10s %s\n" "ID" "STATUS" "NAME"
  printf "%-5s %-10s %s\n" "---" "------" "----"
  for f in "$projects_dir"/*.json; do
    [ -f "$f" ] || continue
    jq -r '"#\(.id)\t\(.status)\t\(.name)"' "$f" | while IFS=$'\t' read -r id status name; do
      printf "%-5s %-10s %s\n" "$id" "$status" "$name"
    done
  done
}

cmd_project_update() {
  local project_id="${3:-}"
  [ -z "$project_id" ] && die "project-update requires <project-id>"
  local padded; padded=$(pad_id "$project_id")
  local file="$ISSUES_ROOT/projects/$padded.json"
  [ -f "$file" ] || biz_err "Project #$project_id does not exist."

  shift 3
  local project; project=$(cat "$file")
  local changed=false

  while [ $# -gt 0 ]; do
    case "$1" in
      --name) project=$(echo "$project" | jq --arg v "$2" '.name = $v'); changed=true; shift 2 ;;
      --desc) project=$(echo "$project" | jq --arg v "$2" '.description = $v'); changed=true; shift 2 ;;
      --status) project=$(echo "$project" | jq --arg v "$2" '.status = $v'); changed=true; shift 2 ;;
      *) die "Unknown arg: $1" ;;
    esac
  done

  if [ "$changed" = true ]; then
    atomic_write "$file" "$project"
    echo "PROJECT-UPDATED: #$project_id"
  fi
}

cmd_project_delete() {
  local project_id="${3:-}"
  [ -z "$project_id" ] && die "project-delete requires <project-id>"
  local padded; padded=$(pad_id "$project_id")
  local file="$ISSUES_ROOT/projects/$padded.json"
  [ -f "$file" ] || biz_err "Project #$project_id does not exist."
  rm "$file"
  echo "PROJECT-DELETED: #$project_id"
}

# ============================================================
# DISPATCH
# ============================================================
[ -z "$CMD" ] && die "Usage: jware-issue.sh <command> <project-dir> [args...]
Commands: init, create, get, list, update, delete, review, vote, quickwins, check-cycle,
          project-create, project-list, project-update, project-delete"

setup_root

case "$CMD" in
  init)           cmd_init "$@" ;;
  create)         cmd_create "$@" ;;
  get)            cmd_get "$@" ;;
  list)           cmd_list "$@" ;;
  update)         cmd_update "$@" ;;
  delete)         cmd_delete "$@" ;;
  review)         cmd_review "$@" ;;
  vote)           cmd_vote "$@" ;;
  quickwins)      cmd_quickwins "$@" ;;
  check-cycle)    cmd_check_cycle "$@" ;;
  project-create) cmd_project_create "$@" ;;
  project-list)   cmd_project_list "$@" ;;
  project-update) cmd_project_update "$@" ;;
  project-delete) cmd_project_delete "$@" ;;
  *) die "Unknown command: $CMD" ;;
esac
