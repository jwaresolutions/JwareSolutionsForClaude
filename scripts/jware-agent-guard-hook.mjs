#!/usr/bin/env node
/**
 * JWare Agent Dispatch Guard
 * Fires on PreToolUse:Agent. If the AI is about to spawn a jware-team-*
 * agent via the Agent tool, injects a STOP warning because Claude Code's
 * internal team launcher does not pass the prompt to the child process.
 * The agent will start with no instructions and exit immediately.
 */

import { readFileSync } from "node:fs";

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

const toolInput = hookData?.tool_input || {};
const agentType = toolInput?.subagent_type || "";

// Only intercept jware-team-* agent spawns
if (!agentType.includes("jware-team-")) {
  process.exit(0);
}

const context = `[JWARE AGENT GUARD — BLOCKED]

STOP. Do NOT use the Agent tool to spawn team agents (${agentType}).

Claude Code has a CONFIRMED BUG: the internal team agent launcher does NOT pass the prompt to the child process. The agent will start with no instructions and exit immediately to a zsh prompt. This is NOT theoretical — it fails every time.

INSTEAD, use the bash spawn script:

1. Write the team prompt to a temp file:
   cat > /tmp/team-{name}-prompt.md << 'TEAM_EOF'
   {full prompt with tasks, context, instructions}
   TEAM_EOF

2. Spawn via script:
   bash $JWARE_HOME/scripts/jware-spawn-team.sh "{name}" "{team-id}" "{session-id}" "$(pwd)" "/tmp/team-{name}-prompt.md"

Cancel this Agent tool call and use the bash script above.`;

console.log(JSON.stringify({
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    additionalContext: context
  }
}));
