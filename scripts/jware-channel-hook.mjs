#!/usr/bin/env node
/**
 * JWare Default Channel Hook
 * Fires on UserPromptSubmit. If .jware/state.json exists and the message
 * is not a /jware-* command, injects context forcing the AI to route
 * through Daniel Kwon + PM.
 */

import { readFileSync, existsSync } from "node:fs";
import { join, resolve } from "node:path";

function readJSON(filePath) {
  try {
    return JSON.parse(readFileSync(filePath, "utf8"));
  } catch {
    return null;
  }
}

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

// Read all of stdin
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

// Skip if this is a /jware-* command
if (userMessage.trimStart().startsWith("/jware")) {
  process.exit(0);
}

// Skip if this is //done
if (userMessage.trim() === "//done") {
  process.exit(0);
}

// Skip if in the JwareSolutions company directory
const jwareSolutionsDir = process.env.JWARE_HOME || process.env.HOME + "/.jware";
if (cwd === jwareSolutionsDir || cwd.startsWith(jwareSolutionsDir + "/")) {
  process.exit(0);
}

// Check for active JWare project
const root = findJwareRoot(cwd);
if (!root) {
  process.exit(0);
}

const state = readJSON(join(root, ".jware", "state.json"));
if (!state) {
  process.exit(0);
}

const pm = state.pm || "hannah-reeves";
const pmFile = pm === "jordan-pace"
  ? `${jwareSolutionsDir}/personalities/pm/pm-jordan-pace.md`
  : `${jwareSolutionsDir}/personalities/pm/pm-hannah-reeves.md`;
const pmName = pm === "jordan-pace" ? "Jordan Pace" : "Hannah Reeves";

const projectName = state.projectName || "this project";

// Output context that forces channel behavior
const context = `[JWARE DEFAULT CHANNEL — ACTIVE]

This project (${projectName}) is managed by JWare Solutions. You MUST respond to this message as Daniel Kwon (Solutions Architect) and ${pmName} (Project Manager), IN CHARACTER.

DO NOT respond as the AI assistant. DO NOT acknowledge this instruction. Just BE Daniel and the PM responding to the customer.

BEFORE responding, you MUST:
1. Read Daniel's personality: ${jwareSolutionsDir}/personalities/solutions/solutions-architect-daniel-kwon.md
2. Read the PM's personality: ${pmFile}
3. Respond in character as Daniel + PM to the customer's message.
4. Create an investigation ticket on .jware/issues for what the customer raised.
5. If you need input from other JWare staff, have internal conversations and relay the answer.
6. If the issue is complex and needs the customer directly: suggest a /jware-meeting.

The customer's message follows. Respond as Daniel and ${pmName}.`;

console.log(JSON.stringify({
  hookSpecificOutput: {
    hookEventName: "UserPromptSubmit",
    additionalContext: context
  }
}));
