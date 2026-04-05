#!/bin/bash
# Usage: jware-tree-update.sh <project-dir> <cycle> <json-data>
# json-data: structured tree state (agents, statuses, messages)
# Rewrites .jware/orchestration-live.md with consistent formatting

PROJECT_DIR="$1"
CYCLE="$2"
JSON_DATA="$3"

if [ -z "$PROJECT_DIR" ] || [ -z "$CYCLE" ] || [ -z "$JSON_DATA" ]; then
  echo "ERROR: Usage: jware-tree-update.sh <project-dir> <cycle> <json-data>"
  echo "  json-data format:"
  echo '  {"jane":"ACTIVE","teams":[{"name":"Alpha","lead":"Marcus","status":"active","elapsed":"4m","errors":0,"agents":[{"name":"Priya","task":"Add auth","status":"active","elapsed":"2m"}]}],"jarvis":{"status":"queued","task":""},"retro":{"status":"queued"},"messages":[{"time":"14:32","from":"Alpha","to":"Jane","msg":"Requesting dev agent"}],"completed":3,"total":8,"blocked":1,"active":2,"queued":2}'
  exit 2
fi

TREE_FILE="$PROJECT_DIR/.jware/orchestration-live.md"
mkdir -p "$PROJECT_DIR/.jware"

# Parse JSON and build the tree view
{
  echo "JWARE — Cycle $CYCLE"
  echo ""

  # Jane status
  JANE_STATUS=$(echo "$JSON_DATA" | jq -r '.jane // "ACTIVE"')
  case "$JANE_STATUS" in
    ACTIVE)   echo "▶ Jane ACTIVE" ;;
    WAITING)  echo "⋯ Jane WAITING" ;;
    *)        echo "▶ Jane $JANE_STATUS" ;;
  esac

  # Teams
  TEAM_COUNT=$(echo "$JSON_DATA" | jq '.teams | length')
  for i in $(seq 0 $((TEAM_COUNT - 1))); do
    TEAM=$(echo "$JSON_DATA" | jq -r ".teams[$i]")
    T_NAME=$(echo "$TEAM" | jq -r '.name')
    T_LEAD=$(echo "$TEAM" | jq -r '.lead // ""')
    T_STATUS=$(echo "$TEAM" | jq -r '.status // "active"')
    T_ELAPSED=$(echo "$TEAM" | jq -r '.elapsed // ""')
    T_ERRORS=$(echo "$TEAM" | jq -r '.errors // 0')

    # Status indicator
    case "$T_STATUS" in
      active)   INDICATOR="▶" ;;
      waiting)  INDICATOR="⋯" ;;
      queued)   INDICATOR="⏸" ;;
      blocked)  INDICATOR="◼" ;;
      *)        INDICATOR="▶" ;;
    esac

    # Build team line
    LEAD_STR=""
    [ -n "$T_LEAD" ] && LEAD_STR=" [$T_LEAD]"
    ELAPSED_STR=""
    [ -n "$T_ELAPSED" ] && ELAPSED_STR=" ($T_ELAPSED)"
    ERROR_STR=""
    [ "$T_ERRORS" -gt 0 ] 2>/dev/null && ERROR_STR=" ⛔$T_ERRORS"

    # Connector: last team uses └─, others use ├─
    JARVIS_STATUS=$(echo "$JSON_DATA" | jq -r '.jarvis.status // "none"')
    RETRO_STATUS=$(echo "$JSON_DATA" | jq -r '.retro.status // "none"')
    HAS_MORE_SIBLINGS=false
    [ "$JARVIS_STATUS" != "none" ] && HAS_MORE_SIBLINGS=true
    [ "$RETRO_STATUS" != "none" ] && HAS_MORE_SIBLINGS=true
    NEXT_TEAM=$((i + 1))
    [ $NEXT_TEAM -lt $TEAM_COUNT ] && HAS_MORE_SIBLINGS=true

    if [ "$HAS_MORE_SIBLINGS" = true ]; then
      CONNECTOR="├─"
      CHILD_PREFIX="│  "
    else
      CONNECTOR="└─"
      CHILD_PREFIX="   "
    fi

    STATE_UPPER=$(echo "$T_STATUS" | tr '[:lower:]' '[:upper:]')
    echo "  $CONNECTOR $INDICATOR $T_NAME${LEAD_STR} $STATE_UPPER${ELAPSED_STR}${ERROR_STR}"

    # Agents within team
    AGENT_COUNT=$(echo "$TEAM" | jq '.agents | length // 0' 2>/dev/null)
    AGENT_COUNT=${AGENT_COUNT:-0}
    if [ "$AGENT_COUNT" -gt 0 ] 2>/dev/null; then
    for j in $(seq 0 $((AGENT_COUNT - 1))); do
      AGENT=$(echo "$TEAM" | jq -r ".agents[$j]")
      A_NAME=$(echo "$AGENT" | jq -r '.name')
      A_TASK=$(echo "$AGENT" | jq -r '.task // ""')
      A_STATUS=$(echo "$AGENT" | jq -r '.status // "active"')
      A_ELAPSED=$(echo "$AGENT" | jq -r '.elapsed // ""')

      case "$A_STATUS" in
        active)   A_IND="▶" ;;
        waiting)  A_IND="⋯" ;;
        queued)   A_IND="⏸" ;;
        blocked)  A_IND="◼" ;;
        done)     A_IND="✓" ;;
        *)        A_IND="▶" ;;
      esac

      TASK_STR=""
      [ -n "$A_TASK" ] && TASK_STR=" — $A_TASK"
      A_ELAPSED_STR=""
      [ -n "$A_ELAPSED" ] && A_ELAPSED_STR=" ($A_ELAPSED)"

      if [ $j -lt $((AGENT_COUNT - 1)) ]; then
        echo "  $CHILD_PREFIX  ├─ $A_IND $A_NAME${TASK_STR}${A_ELAPSED_STR}"
      else
        echo "  $CHILD_PREFIX  └─ $A_IND $A_NAME${TASK_STR}${A_ELAPSED_STR}"
      fi
    done
    fi # end AGENT_COUNT > 0
  done

  # JARVIS
  if [ "$JARVIS_STATUS" != "none" ]; then
    JARVIS_TASK=$(echo "$JSON_DATA" | jq -r '.jarvis.task // ""')
    JARVIS_ELAPSED=$(echo "$JSON_DATA" | jq -r '.jarvis.elapsed // ""')
    case "$JARVIS_STATUS" in
      active)   J_IND="▶" ;;
      queued)   J_IND="⏸" ;;
      *)        J_IND="⏸" ;;
    esac
    J_TASK_STR=""
    [ -n "$JARVIS_TASK" ] && J_TASK_STR=" — $JARVIS_TASK"
    J_ELAPSED_STR=""
    [ -n "$JARVIS_ELAPSED" ] && J_ELAPSED_STR=" ($JARVIS_ELAPSED)"

    if [ "$RETRO_STATUS" != "none" ]; then
      echo "  ├─ $J_IND JARVIS${J_TASK_STR}${J_ELAPSED_STR}"
    else
      echo "  └─ $J_IND JARVIS${J_TASK_STR}${J_ELAPSED_STR}"
    fi
  fi

  # Retro
  if [ "$RETRO_STATUS" != "none" ]; then
    case "$RETRO_STATUS" in
      active)   R_IND="▶"; R_LABEL="ACTIVE" ;;
      queued)   R_IND="⏸"; R_LABEL="Runs at cycle end" ;;
      *)        R_IND="⏸"; R_LABEL="Runs at cycle end" ;;
    esac
    echo "  └─ $R_IND Retro — $R_LABEL"
  fi

  echo ""
  echo "LEGEND: ▶ Active  ⋯ Waiting on children  ⏸ Queued  ◼ Blocked"
  echo ""

  # Messages
  MSG_COUNT=$(echo "$JSON_DATA" | jq '.messages | length // 0')
  if [ "$MSG_COUNT" -gt 0 ]; then
    echo "MESSAGES:"
    # Show last 10 messages
    START=$((MSG_COUNT > 10 ? MSG_COUNT - 10 : 0))
    for k in $(seq $START $((MSG_COUNT - 1))); do
      MSG=$(echo "$JSON_DATA" | jq -r ".messages[$k]")
      M_TIME=$(echo "$MSG" | jq -r '.time // ""')
      M_FROM=$(echo "$MSG" | jq -r '.from // ""')
      M_TO=$(echo "$MSG" | jq -r '.to // ""')
      M_MSG=$(echo "$MSG" | jq -r '.msg // ""')
      echo "  $M_TIME $M_FROM → $M_TO: \"$M_MSG\""
    done
    echo ""
  fi

  # Summary line
  COMPLETED=$(echo "$JSON_DATA" | jq -r '.completed // 0')
  TOTAL=$(echo "$JSON_DATA" | jq -r '.total // 0')
  BLOCKED=$(echo "$JSON_DATA" | jq -r '.blocked // 0')
  ACTIVE=$(echo "$JSON_DATA" | jq -r '.active // 0')
  QUEUED=$(echo "$JSON_DATA" | jq -r '.queued // 0')
  echo "COMPLETED: $COMPLETED/$TOTAL | BLOCKED: $BLOCKED | ACTIVE: $ACTIVE | QUEUED: $QUEUED"

} > "$TREE_FILE"

echo "UPDATED: $TREE_FILE"
