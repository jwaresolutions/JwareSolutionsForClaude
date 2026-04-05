#!/bin/bash
# Usage: jware-deploy-check.sh <project-dir>
# Detects CI/CD config, triggers the pipeline or build, waits for result.
# Returns: 0 if passes, 1 if fails (prints error output)

PROJECT_DIR="$1"
TIMEOUT="${2:-300}" # Default 5 minute timeout

if [ -z "$PROJECT_DIR" ]; then
  echo "ERROR: Usage: jware-deploy-check.sh <project-dir> [timeout_seconds]"
  exit 2
fi

cd "$PROJECT_DIR" || { echo "ERROR: Cannot cd to $PROJECT_DIR"; exit 2; }

# Detect CI/CD configuration
if [ -d ".github/workflows" ]; then
  CI_TYPE="github-actions"
elif [ -f "Makefile" ]; then
  CI_TYPE="makefile"
elif [ -f "Dockerfile" ]; then
  CI_TYPE="docker"
elif [ -f "package.json" ] && jq -e '.scripts.build' package.json >/dev/null 2>&1; then
  CI_TYPE="npm-build"
elif [ -f "Cargo.toml" ]; then
  CI_TYPE="cargo"
elif [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then
  CI_TYPE="python"
else
  echo "SKIP: No CI/CD configuration detected in $PROJECT_DIR"
  exit 0
fi

echo "DETECTED: $CI_TYPE"

run_with_timeout() {
  local cmd="$1"
  timeout "$TIMEOUT" bash -c "$cmd" 2>&1
  return $?
}

case "$CI_TYPE" in
  github-actions)
    # Check if gh CLI is available and repo has remote
    if ! command -v gh &>/dev/null; then
      echo "SKIP: gh CLI not available for GitHub Actions check"
      exit 0
    fi
    # Trigger workflow run on current branch
    BRANCH=$(git branch --show-current 2>/dev/null)
    if [ -z "$BRANCH" ]; then
      echo "SKIP: Not on a git branch"
      exit 0
    fi
    # Find the first workflow file
    WORKFLOW=$(ls .github/workflows/*.yml .github/workflows/*.yaml 2>/dev/null | head -1)
    if [ -z "$WORKFLOW" ]; then
      echo "SKIP: No workflow files found"
      exit 0
    fi
    WORKFLOW_NAME=$(basename "$WORKFLOW")
    echo "RUNNING: gh workflow run $WORKFLOW_NAME on $BRANCH"
    OUTPUT=$(gh workflow run "$WORKFLOW_NAME" --ref "$BRANCH" 2>&1)
    if [ $? -ne 0 ]; then
      echo "FAIL: Could not trigger workflow: $OUTPUT"
      exit 1
    fi
    # Wait for the run to appear and complete
    sleep 5
    RUN_ID=$(gh run list --workflow="$WORKFLOW_NAME" --branch="$BRANCH" --limit=1 --json databaseId -q '.[0].databaseId' 2>/dev/null)
    if [ -n "$RUN_ID" ]; then
      echo "WAITING: Run #$RUN_ID (timeout ${TIMEOUT}s)"
      OUTPUT=$(timeout "$TIMEOUT" gh run watch "$RUN_ID" --exit-status 2>&1)
      STATUS=$?
      if [ $STATUS -eq 0 ]; then
        echo "PASS: GitHub Actions workflow succeeded"
        exit 0
      else
        echo "FAIL: GitHub Actions workflow failed"
        echo "$OUTPUT"
        exit 1
      fi
    else
      echo "SKIP: Could not find triggered run"
      exit 0
    fi
    ;;

  makefile)
    if grep -q '^build:' Makefile || grep -q '^all:' Makefile; then
      TARGET="build"
      grep -q '^build:' Makefile || TARGET="all"
      echo "RUNNING: make $TARGET"
      OUTPUT=$(run_with_timeout "make $TARGET")
      STATUS=$?
      if [ $STATUS -eq 0 ]; then
        echo "PASS: make $TARGET succeeded"
        exit 0
      else
        echo "FAIL: make $TARGET failed (exit $STATUS)"
        echo "$OUTPUT"
        exit 1
      fi
    else
      echo "SKIP: Makefile has no build or all target"
      exit 0
    fi
    ;;

  docker)
    echo "RUNNING: docker build"
    OUTPUT=$(run_with_timeout "docker build -t jware-deploy-check .")
    STATUS=$?
    if [ $STATUS -eq 0 ]; then
      echo "PASS: Docker build succeeded"
      docker rmi jware-deploy-check >/dev/null 2>&1
      exit 0
    else
      echo "FAIL: Docker build failed (exit $STATUS)"
      echo "$OUTPUT"
      exit 1
    fi
    ;;

  npm-build)
    # Install deps if needed
    if [ ! -d "node_modules" ]; then
      echo "RUNNING: npm install"
      npm install --silent 2>&1
    fi
    echo "RUNNING: npm run build"
    OUTPUT=$(run_with_timeout "npm run build")
    STATUS=$?
    if [ $STATUS -eq 0 ]; then
      echo "PASS: npm build succeeded"
      exit 0
    else
      echo "FAIL: npm build failed (exit $STATUS)"
      echo "$OUTPUT"
      exit 1
    fi
    ;;

  cargo)
    echo "RUNNING: cargo build"
    OUTPUT=$(run_with_timeout "cargo build 2>&1")
    STATUS=$?
    if [ $STATUS -eq 0 ]; then
      echo "PASS: cargo build succeeded"
      exit 0
    else
      echo "FAIL: cargo build failed (exit $STATUS)"
      echo "$OUTPUT"
      exit 1
    fi
    ;;

  python)
    if [ -f "pyproject.toml" ]; then
      echo "RUNNING: python -m build (or pip install)"
      OUTPUT=$(run_with_timeout "pip install -e . 2>&1")
    else
      OUTPUT=$(run_with_timeout "pip install -e . 2>&1")
    fi
    STATUS=$?
    if [ $STATUS -eq 0 ]; then
      echo "PASS: Python build succeeded"
      exit 0
    else
      echo "FAIL: Python build failed (exit $STATUS)"
      echo "$OUTPUT"
      exit 1
    fi
    ;;
esac
