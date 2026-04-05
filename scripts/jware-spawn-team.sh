#!/bin/bash
# Usage: jware-spawn-team.sh <team-name> <team-id> <session-id> <project-dir> <prompt-file>
# Spawns a JWare team agent in a new tmux pane with the given prompt.

TEAM_NAME="$1"
TEAM_ID="$2"
SESSION_ID="$3"
PROJECT_DIR="$4"
PROMPT_FILE="$5"

if [ -z "$TEAM_NAME" ] || [ -z "$SESSION_ID" ] || [ -z "$PROJECT_DIR" ] || [ -z "$PROMPT_FILE" ]; then
  echo "ERROR: Usage: jware-spawn-team.sh <team-name> <team-id> <session-id> <project-dir> <prompt-file>"
  exit 1
fi

if [ ! -f "$PROMPT_FILE" ]; then
  echo "ERROR: Prompt file not found: $PROMPT_FILE"
  exit 1
fi

PROMPT=$(cat "$PROMPT_FILE")

# Spawn the team agent in a new tmux pane
PANE_ID=$(tmux split-window -h -P -F "#{pane_id}" "cd '$PROJECT_DIR' && claude --agent-id '${TEAM_NAME}@${TEAM_ID}' --agent-name '$TEAM_NAME' --team-name '$TEAM_ID' --parent-session-id '$SESSION_ID' --dangerously-skip-permissions --model claude-sonnet-4-6 \"$PROMPT\"")

echo "SPAWNED: team=$TEAM_NAME pane=$PANE_ID"
