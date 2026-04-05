#!/usr/bin/env node
/**
 * JWare Meeting Guard Hook
 * Fires on every user prompt. If a JWare meeting is active and the user
 * did NOT send //done, injects a reminder that the meeting must not end.
 * If the user sent //done, injects permission to close the meeting.
 */

import { readFileSync, existsSync } from "node:fs";
import { join, resolve } from "node:path";

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

// Skip if not in a JWare project
const root = findJwareRoot(cwd);
if (!root) {
  process.exit(0);
}

// Skip if this IS a /jware command (skills handle themselves)
if (userMessage.trimStart().startsWith("/jware")) {
  process.exit(0);
}

// Check if //done was sent
if (userMessage.trim() === "//done") {
  const context = `[MEETING TERMINATION AUTHORIZED]

The customer sent //done. You may now close the meeting. Have the PM summarize action items and close in character. Then proceed to capture outcomes (save transcript, generate events, update issues).`;

  console.log(JSON.stringify({
    hookSpecificOutput: {
      hookEventName: "UserPromptSubmit",
      additionalContext: context
    }
  }));
  process.exit(0);
}

// For all other messages during a meeting, remind not to close
// We can't perfectly detect if a meeting is active, but we can always
// inject the reminder — it's harmless if no meeting is running
const context = `[MEETING GUARD — ACTIVE]

If a JWare meeting is currently in progress: DO NOT close, end, adjourn, or wrap up the meeting. The meeting continues until the customer sends //done. Even if the agenda is covered, even if there is a natural pause, even if action items are captured — the meeting is NOT over until //done. You may SUGGEST ending ("Anything else before we wrap?") but you must WAIT for //done.`;

console.log(JSON.stringify({
  hookSpecificOutput: {
    hookEventName: "UserPromptSubmit",
    additionalContext: context
  }
}));
