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

# Read layout config from ~/.jware/layout.json (personal preference, not in repo)
# Config keys: teamLayout ("bottom-columns" or "right-stack")
LAYOUT_FILE="$HOME/.jware/layout.json"
TEAM_LAYOUT="right-stack"  # default
if [ -f "$LAYOUT_FILE" ]; then
  TL=$(python3 -c "import json,sys; print(json.load(open('$LAYOUT_FILE')).get('teamLayout',''))" 2>/dev/null)
  [ -n "$TL" ] && TEAM_LAYOUT="$TL"
fi

# Determine split direction based on layout and pane count
PANE_COUNT=$(tmux list-panes -F "#{pane_id}" | wc -l | tr -d ' ')
SPLIT_ARGS="-h"
if [ "$TEAM_LAYOUT" = "bottom-columns" ]; then
  if [ "$PANE_COUNT" -le 2 ]; then
    # First team — split below the main agent pane
    SPLIT_ARGS="-v -t 0"
  else
    # Subsequent teams — split right from the last pane in the bottom row
    LAST_PANE=$(tmux list-panes -F "#{pane_id}" | tail -1)
    SPLIT_ARGS="-h -t ${LAST_PANE}"
  fi
fi

# The prompt file is read inside the pane via $(cat ...) to avoid quoting issues
# with complex multi-line prompts containing quotes or special characters.
PANE_ID=$(tmux split-window ${SPLIT_ARGS} -P -F "#{pane_id}" "cd '${PROJECT_DIR}' && claude --agent-id '${TEAM_NAME}@${TEAM_ID}' --agent-name '${TEAM_NAME}' --team-name '${TEAM_ID}' --parent-session-id '${SESSION_ID}' --dangerously-skip-permissions --model claude-sonnet-4-6 \"\$(cat '${PROMPT_FILE}')\"")

# Verify the agent started (give it a moment to initialize)
sleep 2
PANE_CMD=$(tmux display-message -t "$PANE_ID" -p "#{pane_current_command}" 2>/dev/null)
if [ "$PANE_CMD" = "zsh" ] || [ "$PANE_CMD" = "bash" ]; then
  echo "WARNING: Agent in pane $PANE_ID may have failed to start (showing $PANE_CMD)"
fi

echo "SPAWNED: team=$TEAM_NAME pane=$PANE_ID"
