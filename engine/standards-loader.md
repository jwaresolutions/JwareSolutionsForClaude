# Engine Module: Standards and Domain Loader

**Purpose:** Loads the correct standards modules and domain briefings for a developer dispatch based on the team configuration and task context. Sits alongside the personality-loader — personality gives behavioral traits, this module gives professional knowledge.

---

## 1. Directory Structure

```
$JWARE_HOME/
  standards/       # Reusable quality rules — loaded by reference from team configs
  domains/         # Domain knowledge — organized by category
    infrastructure/
    application/
    mobile/
    web-frontend/
    web-backend/
    financial/
  teams/           # Team specialization configs — one per team
```

---

## 2. Loading Algorithm

```
FUNCTION loadStandardsAndDomains(teamSlug, taskContext):

  1. Read team config: $JWARE_HOME/teams/{teamSlug}.md
  
  2. Load CORE STANDARDS (always loaded for this team):
     - Read the "Core Standards" section of the team config
     - For each listed path, read the file
     - These are always included in the dispatch prompt
  
  3. Scan task for DOMAIN TRIGGERS:
     - Read the "Domain Triggers" table from the team config
     - Match task acceptance criteria, affected files, and task description
       against the trigger keywords in column 1
     - For each match:
       a. Add the listed domain modules to the load list
       b. Add the listed SME slugs to the consultation list
     - Deduplicate: if a domain module appears multiple times, load it once
  
  4. Load DOMAIN MODULES:
     - For each module in the load list, read the file from $JWARE_HOME/domains/
     - These are included in the dispatch prompt under "## Domain Context"
  
  5. Return:
     {
       coreStandards: [list of loaded standard module contents],
       domainModules: [list of loaded domain module contents],
       smeConsultations: [list of SME slugs to consult before dispatch],
       teamTechContext: [the "Default Tech Context" section from team config]
     }

INPUTS:
  - teamSlug: string (e.g., "alpha", "bravo", "charlie", "trading")
  - taskContext: {
      title: string,           -- task/issue title
      acceptanceCriteria: string, -- full acceptance criteria text
      affectedFiles: string[],    -- files the task will touch
      labels: string[]            -- issue labels (e.g., "security", "risk")
    }

OUTPUT:
  - Structured object ready to be injected into the dispatch prompt
```

---

## 3. SME Consultation Flow

When the loader returns SME slugs in `smeConsultations`, the orchestrator runs a consultation BEFORE dispatching the developer:

```
FUNCTION consultSME(smeSlug, taskSummary, domainQuestions):

  1. Load the SME's personality using personality-loader:
     - agentType: "meeting" (full personality for conversational context)
     - This preserves the personality for consultations while coding agents
       get the stripped behavioral version
  
  2. Dispatch a short consultation:
     Agent tool:
       subagent_type: "jware-dev-senior" (or appropriate role for the SME)
       model: "sonnet"
       prompt: [Full personality] + "You are being consulted on a task.
               Task: {taskSummary}
               Questions: {domainQuestions}
               Provide specific, actionable guidance. Keep it under 500 words.
               Focus on: pitfalls to avoid, patterns to follow, edge cases to test."
  
  3. Capture the response as structured domain guidance
  
  4. Include in the developer's task prompt under:
     ## Domain Guidance (from {SME name})
     {consultation response}
```

---

## 4. Prompt Assembly Order

The full dispatch prompt is assembled in this order:

```
1. PERSONALITY (from personality-loader — behavioral constraints for coding agents)
2. ROLE PROMPT (from $JWARE_HOME/agents/{role}.md — seniority-level expectations)
3. CORE STANDARDS (from team config — always loaded)
4. DOMAIN MODULES (from domain triggers — loaded when relevant)
5. DOMAIN GUIDANCE (from SME consultations — when triggered)
6. TEAM TECH CONTEXT (from team config — default tech stack)
7. TASK DETAILS (acceptance criteria, affected files, context)
```

If the total prompt exceeds 8000 tokens, the orchestrator should:
- Keep: role prompt, core standards, task details (non-negotiable)
- Summarize: domain modules (extract key concerns and pitfalls only)
- Trim: SME guidance (keep recommendations, drop reasoning)
- Never trim: personality behavioral constraints

---

## 5. Project-Specific Overrides

A project can override team defaults by placing a `.jware/team-overrides.json` file:

```json
{
  "alpha": {
    "additionalStandards": ["standards/financial-precision.md"],
    "additionalDomainTriggers": [
      {
        "keywords": ["calendar", "market hours", "holiday"],
        "domains": ["financial/trading-systems.md"],
        "consult": ["owen-blake"]
      }
    ]
  }
}
```

This allows project-specific domain knowledge without modifying the global team configs.

---

## 6. Capture Integration

When `.jware/capture-task-prompts.json` exists with `"enabled": true`, the loader writes the full assembled prompt (all 7 layers) to `.jware/agent-context/dispatches/` BEFORE dispatching. This includes which standards were loaded, which domains were triggered, and which SME consultations occurred.
