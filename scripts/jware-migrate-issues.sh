#!/bin/bash
# jware-migrate-issues.sh — Migrate .issuetracker/ to .jware/issues/
# Usage: jware-migrate-issues.sh <project-dir>
# One-time migration script.

set -euo pipefail

PROJECT_DIR="${1:-}"

if [ -z "$PROJECT_DIR" ]; then
  echo "ERROR: Usage: jware-migrate-issues.sh <project-dir>"
  exit 2
fi

OLD="$PROJECT_DIR/.issuetracker"
NEW="$PROJECT_DIR/.jware/issues"

if [ ! -d "$OLD" ]; then
  echo "SKIP: No .issuetracker/ in $PROJECT_DIR"
  exit 0
fi

if [ -d "$NEW/issues" ] && ls "$NEW/issues"/*.json >/dev/null 2>&1; then
  echo "SKIP: .jware/issues/ already has issue files in $PROJECT_DIR"
  exit 0
fi

# Create target structure
mkdir -p "$NEW/issues" "$NEW/projects" "$NEW/assets"

# Move config
[ -f "$OLD/config.json" ] && mv "$OLD/config.json" "$NEW/config.json"

# Move issues
if [ -d "$OLD/issues" ]; then
  for f in "$OLD/issues"/*.json "$OLD/issues"/.gitkeep; do
    [ -f "$f" ] && mv "$f" "$NEW/issues/"
  done
  rmdir "$OLD/issues" 2>/dev/null || true
fi

# Move projects
if [ -d "$OLD/projects" ]; then
  for f in "$OLD/projects"/*.json "$OLD/projects"/.gitkeep; do
    [ -f "$f" ] && mv "$f" "$NEW/projects/"
  done
  rmdir "$OLD/projects" 2>/dev/null || true
fi

# Move assets
if [ -d "$OLD/assets" ]; then
  for d in "$OLD/assets"/*/; do
    [ -d "$d" ] && mv "$d" "$NEW/assets/"
  done
  # Move any remaining files (like .gitkeep)
  for f in "$OLD/assets"/.gitkeep; do
    [ -f "$f" ] && mv "$f" "$NEW/assets/"
  done
  rmdir "$OLD/assets" 2>/dev/null || true
fi

# Remove old directory (only if empty)
rmdir "$OLD" 2>/dev/null || rm -rf "$OLD"

# Count what was migrated
ISSUE_COUNT=$(ls "$NEW/issues"/*.json 2>/dev/null | wc -l | tr -d ' ')
PROJECT_COUNT=$(ls "$NEW/projects"/*.json 2>/dev/null | wc -l | tr -d ' ')

echo "MIGRATED: $PROJECT_DIR ($ISSUE_COUNT issues, $PROJECT_COUNT projects)"
