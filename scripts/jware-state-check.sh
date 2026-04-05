#!/bin/bash
# jware-state-check.sh — Validate JWare project prerequisites
# Usage: jware-state-check.sh <project-dir> [--require-phase P] [--require-active] [--require-registry]
# Output: JSON state summary if OK, error message if failed
# Exit: 0 = OK, 1 = failed check

set -euo pipefail

PROJECT_DIR="${1:-}"
[ -z "$PROJECT_DIR" ] && { echo '{"error":"Usage: jware-state-check.sh <project-dir> [options]"}'; exit 2; }

shift
REQUIRE_PHASE=""
REQUIRE_ACTIVE=false
REQUIRE_REGISTRY=false

while [ $# -gt 0 ]; do
  case "$1" in
    --require-phase) REQUIRE_PHASE="$2"; shift 2 ;;
    --require-active) REQUIRE_ACTIVE=true; shift ;;
    --require-registry) REQUIRE_REGISTRY=true; shift ;;
    *) shift ;;
  esac
done

STATE_FILE="$PROJECT_DIR/.jware/state.json"
REGISTRY="${JWARE_HOME:-$HOME/.jware}/.jware/registry.json"

# Check state.json exists
if [ ! -f "$STATE_FILE" ]; then
  echo '{"ok":false,"error":"No .jware/state.json found. Run /jware to start a project."}'
  exit 1
fi

# Read state
STATE=$(cat "$STATE_FILE")
PHASE=$(echo "$STATE" | jq -r '.phase // "unknown"')
STATUS=$(echo "$STATE" | jq -r '.status // "unknown"')
PROJECT_NAME=$(echo "$STATE" | jq -r '.projectName // "unknown"')
PM=$(echo "$STATE" | jq -r '.pm // ""')
VISIBILITY=$(echo "$STATE" | jq -r '.visibility // 1')
PROJECT_ID=$(echo "$STATE" | jq -r '.projectId // ""')

# Check phase requirement
if [ -n "$REQUIRE_PHASE" ] && [ "$PHASE" != "$REQUIRE_PHASE" ]; then
  echo "{\"ok\":false,\"error\":\"Phase is '$PHASE', required '$REQUIRE_PHASE'\"}"
  exit 1
fi

# Check active requirement
if [ "$REQUIRE_ACTIVE" = true ] && [ "$STATUS" != "active" ]; then
  if [ "$PHASE" = "completed" ]; then
    echo '{"ok":false,"error":"This project has been delivered. All work is complete."}'
  elif [ "$PHASE" = "intake" ]; then
    echo '{"ok":false,"error":"This project is still in intake. Complete /jware first."}'
  else
    echo "{\"ok\":false,\"error\":\"Project status is '$STATUS', expected 'active'\"}"
  fi
  exit 1
fi

# Check registry
if [ "$REQUIRE_REGISTRY" = true ] && [ ! -f "$REGISTRY" ]; then
  echo '{"ok":false,"error":"Central registry not found at expected path.","warning":true}'
  # Warning only — don't block
fi

# Check for scoping lock
SCOPING_LOCK=false
[ -f "$PROJECT_DIR/.jware/scoping.lock" ] && SCOPING_LOCK=true

# Check for auto state
AUTO_STATUS="none"
if [ -f "$PROJECT_DIR/.jware/auto-state.json" ]; then
  AUTO_STATUS=$(jq -r '.status // "unknown"' "$PROJECT_DIR/.jware/auto-state.json")
fi

# Output state summary
jq -n \
  --arg name "$PROJECT_NAME" \
  --arg phase "$PHASE" \
  --arg status "$STATUS" \
  --arg pm "$PM" \
  --argjson vis "$VISIBILITY" \
  --arg pid "$PROJECT_ID" \
  --argjson scopeLock "$SCOPING_LOCK" \
  --arg autoStatus "$AUTO_STATUS" \
  '{
    ok: true,
    projectName: $name,
    phase: $phase,
    status: $status,
    pm: $pm,
    visibility: $vis,
    projectId: $pid,
    scopingLock: $scopeLock,
    autoStatus: $autoStatus
  }'
