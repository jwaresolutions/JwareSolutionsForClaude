#!/bin/bash
# Usage: jware-file-lock.sh <action> <project-dir> <file-path> <team> <task-id>
# Actions: acquire | release | check | force-release | release-all-for-task
# Manages .jware/file-locks.json

ACTION="$1"
PROJECT_DIR="$2"
FILE_PATH="$3"
TEAM="$4"
TASK_ID="$5"
LOCKS_FILE="$PROJECT_DIR/.jware/file-locks.json"

if [ -z "$ACTION" ] || [ -z "$PROJECT_DIR" ]; then
  echo "ERROR: Usage: jware-file-lock.sh <action> <project-dir> <file-path> <team> <task-id>"
  exit 2
fi

# Ensure locks file exists
if [ ! -f "$LOCKS_FILE" ]; then
  echo '{"locks":{}}' > "$LOCKS_FILE"
fi

NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)

case "$ACTION" in
  acquire)
    if [ -z "$FILE_PATH" ] || [ -z "$TEAM" ] || [ -z "$TASK_ID" ]; then
      echo "ERROR: acquire requires <file-path> <team> <task-id>"
      exit 2
    fi
    # Check if already locked by another team/task
    EXISTING=$(jq -r --arg f "$FILE_PATH" '.locks[$f] // empty' "$LOCKS_FILE")
    if [ -n "$EXISTING" ]; then
      LOCK_TEAM=$(echo "$EXISTING" | jq -r '.team')
      LOCK_TASK=$(echo "$EXISTING" | jq -r '.task')
      if [ "$LOCK_TEAM" = "$TEAM" ] && [ "$LOCK_TASK" = "$TASK_ID" ]; then
        echo "OK: Already locked by $TEAM/$TASK_ID"
        exit 0
      fi
      LOCK_AT=$(echo "$EXISTING" | jq -r '.lockedAt')
      echo "BLOCKED: $FILE_PATH locked by team=$LOCK_TEAM task=$LOCK_TASK since $LOCK_AT"
      exit 1
    fi
    # Acquire the lock
    jq --arg f "$FILE_PATH" --arg t "$TEAM" --arg id "$TASK_ID" --arg now "$NOW" \
      '.locks[$f] = {"team": $t, "task": $id, "lockedAt": $now}' \
      "$LOCKS_FILE" > "${LOCKS_FILE}.tmp" && mv "${LOCKS_FILE}.tmp" "$LOCKS_FILE"
    echo "ACQUIRED: $FILE_PATH by $TEAM/$TASK_ID"
    exit 0
    ;;

  release)
    if [ -z "$FILE_PATH" ]; then
      echo "ERROR: release requires <file-path>"
      exit 2
    fi
    jq --arg f "$FILE_PATH" 'del(.locks[$f])' \
      "$LOCKS_FILE" > "${LOCKS_FILE}.tmp" && mv "${LOCKS_FILE}.tmp" "$LOCKS_FILE"
    echo "RELEASED: $FILE_PATH"
    exit 0
    ;;

  check)
    if [ -z "$FILE_PATH" ]; then
      echo "ERROR: check requires <file-path>"
      exit 2
    fi
    EXISTING=$(jq -r --arg f "$FILE_PATH" '.locks[$f] // empty' "$LOCKS_FILE")
    if [ -n "$EXISTING" ]; then
      LOCK_TEAM=$(echo "$EXISTING" | jq -r '.team')
      LOCK_TASK=$(echo "$EXISTING" | jq -r '.task')
      LOCK_AT=$(echo "$EXISTING" | jq -r '.lockedAt')
      echo "LOCKED: $FILE_PATH by team=$LOCK_TEAM task=$LOCK_TASK since $LOCK_AT"
      exit 1
    fi
    echo "AVAILABLE: $FILE_PATH"
    exit 0
    ;;

  force-release)
    if [ -z "$FILE_PATH" ]; then
      echo "ERROR: force-release requires <file-path>"
      exit 2
    fi
    EXISTING=$(jq -r --arg f "$FILE_PATH" '.locks[$f] // empty' "$LOCKS_FILE")
    if [ -n "$EXISTING" ]; then
      LOCK_TEAM=$(echo "$EXISTING" | jq -r '.team')
      LOCK_TASK=$(echo "$EXISTING" | jq -r '.task')
      echo "FORCE-RELEASED: $FILE_PATH (was held by team=$LOCK_TEAM task=$LOCK_TASK)"
    else
      echo "FORCE-RELEASED: $FILE_PATH (was not locked)"
    fi
    jq --arg f "$FILE_PATH" 'del(.locks[$f])' \
      "$LOCKS_FILE" > "${LOCKS_FILE}.tmp" && mv "${LOCKS_FILE}.tmp" "$LOCKS_FILE"
    exit 0
    ;;

  release-all-for-task)
    if [ -z "$TASK_ID" ]; then
      echo "ERROR: release-all-for-task requires <task-id> (pass as 5th arg)"
      exit 2
    fi
    RELEASED=$(jq -r --arg id "$TASK_ID" \
      '[.locks | to_entries[] | select(.value.task == $id) | .key] | join(", ")' \
      "$LOCKS_FILE")
    jq --arg id "$TASK_ID" \
      '.locks |= with_entries(select(.value.task != $id))' \
      "$LOCKS_FILE" > "${LOCKS_FILE}.tmp" && mv "${LOCKS_FILE}.tmp" "$LOCKS_FILE"
    if [ -n "$RELEASED" ]; then
      echo "RELEASED-ALL: $RELEASED (task=$TASK_ID)"
    else
      echo "RELEASED-ALL: no locks held by task=$TASK_ID"
    fi
    exit 0
    ;;

  *)
    echo "ERROR: Unknown action '$ACTION'. Use: acquire | release | check | force-release | release-all-for-task"
    exit 2
    ;;
esac
