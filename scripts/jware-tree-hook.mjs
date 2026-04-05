#!/usr/bin/env node
/**
 * JWare Tree View Hook
 * Fires on UserPromptSubmit. When /jware-auto is invoked, creates the
 * orchestration-live.md file and spawns a tmux pane to display it.
 */

import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { join, resolve } from "node:path";
import { execSync } from "node:child_process";

function findJwareRoot(startDir) {
  let dir = startDir;
  for (let i = 0; i < 20; i++) {
    if (existsSync(join(dir, ".jware", "state.json"))) {
      return dir;
    }
    const parent = resolve(dir, "..");
    if (parent === dir) break;
    dir = parent;
  }
  return null;
}

// Read stdin
let input = "";
try {
  input = readFileSync("/dev/stdin", "utf8");
} catch {
  process.exit(0);
}

let hookData;
try {
  hookData = JSON.parse(input);
} catch {
  process.exit(0);
}

const userMessage = hookData?.prompt || "";
const cwd = hookData?.cwd || process.cwd();

// Only trigger on /jware-auto
if (!userMessage.trimStart().startsWith("/jware-auto")) {
  process.exit(0);
}

// Check for active JWare project
const root = findJwareRoot(cwd);
if (!root) {
  process.exit(0);
}

const treePath = join(root, ".jware", "orchestration-live.md");
const fileLockPath = join(root, ".jware", "file-locks.json");

// Create the orchestration-live.md file
try {
  const initialTree = `JWARE — Initializing

▶ Jane STARTING
  └─ ⏸ Loading project state...

LEGEND: ▶ Active  ⋯ Waiting on children  ⏸ Queued  ◼ Blocked

MESSAGES:
  (none yet)

COMPLETED: 0/? | BLOCKED: 0 | ACTIVE: 1 | QUEUED: 0
`;
  writeFileSync(treePath, initialTree);
} catch {
  process.exit(0);
}

// Initialize file locks
try {
  writeFileSync(fileLockPath, '{"locks":{}}');
} catch {
  // non-fatal
}

// Check if a tree view pane already exists by looking for watch processes on this file
let paneExists = false;
try {
  const panes = execSync("tmux list-panes -a -F '#{pane_id} #{pane_current_command}'", { encoding: "utf8", timeout: 3000 });
  if (panes.includes("watch")) {
    paneExists = true;
  }
} catch {
  // not in tmux or tmux not available
  process.exit(0);
}

// Spawn tree view pane if not already present
if (!paneExists) {
  try {
    execSync(`tmux split-window -v -l 15 "watch -n 1 cat '${treePath}'"`, { timeout: 5000 });
  } catch {
    // fallback without watch
    try {
      execSync(`tmux split-window -v -l 15 "while true; do clear; cat '${treePath}' 2>/dev/null; sleep 1; done"`, { timeout: 5000 });
    } catch {
      // give up on pane creation
    }
  }
}

// Output context reminding Jane to update the tree view
const context = `[JWARE TREE VIEW — INITIALIZED]

The orchestration tree view file has been created at .jware/orchestration-live.md and a tmux pane is displaying it. You MUST update this file after every significant action:
- Dispatching an agent
- Receiving a result from an agent
- Changing a blocker status
- Completing a task

Rewrite the entire file each time using the tree format defined in the skill file. The customer is watching this pane. If you do not update it, the customer sees stale data.

File locks have been initialized at .jware/file-locks.json.`;

console.log(JSON.stringify({
  hookSpecificOutput: {
    hookEventName: "UserPromptSubmit",
    additionalContext: context
  }
}));
