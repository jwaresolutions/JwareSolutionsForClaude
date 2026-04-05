# State Manager — Engine Module

## Purpose

Defines all state file schemas, initialization procedures, phase transitions, and atomic write protocols for JWare Solutions projects.

---

## 1. State File Locations

| File | Location | Purpose |
|------|----------|---------|
| `state.json` | `.jware/` in project | Project state, phase, teams, visibility, task counts |
| `events.json` | `.jware/` in project | Event queue (pending + processed) |
| `risks.json` | `.jware/` in project | Risk register from Daniel's assessment |
| `decisions/*.md` | `.jware/decisions/` in project | Decision log entries with rationale |
| `meetings/*.md` | `.jware/meetings/` in project | Meeting transcripts at visibility level |
| `reviews/*.md` | `.jware/reviews/` in project | Code review records between personalities |
| `registry.json` | `$JWARE_HOME/.jware/` | Central project registry |

---

## 2. state.json Schema

```json
{
  "projectId": "proj_NNN",
  "projectName": "string — derived from project directory name",
  "projectPath": "string — absolute path to the project directory",
  "phase": "string — one of: intake, kickoff, development, review, blocked, delivery, completed",
  "visibility": "integer — 1, 2, or 3",
  "greenfield": "boolean — true if no existing codebase",
  "teams": {
    "primary": {
      "lead": "string — personality slug (e.g., marcus-chen)",
      "seniors": ["string — personality slugs"],
      "mids": ["string — personality slugs"],
      "juniors": ["string — personality slugs"],
      "qa": "string — personality slug"
    },
    "secondary": "object|null — same structure as primary, null if not allocated",
    "tertiary": "object|null — same structure as primary, null if not allocated"
  },
  "tradingDivision": {
    "active": "boolean",
    "members": ["string — personality slugs from trading division"]
  },
  "pm": "string — personality slug (hannah-reeves or jordan-pace)",
  "solutionsArchitect": "daniel-kwon",
  "startedAt": "string — ISO 8601 timestamp",
  "lastActivity": "string — ISO 8601 timestamp",
  "currentCycle": "integer — increments each time /jware-auto runs",
  "totalTasks": "integer — total issues created during scoping",
  "completedTasks": "integer — issues marked done",
  "inProgressTasks": "integer — issues in_progress",
  "blockedTasks": "integer — issues blocked or decision-needed",
  "decisionsNeeded": "integer — issues with label decision-needed and no userVote",
  "branchingStrategy": "string — chosen by dev lead (e.g., branch-per-feature, branch-per-team)",
  "techStack": ["string — detected or declared technologies"],
  "risks": "integer — count of open risks in risks.json"
}
```

---

## 3. events.json Schema

An array of event objects. Each event conforms to:

```json
{
  "id": "string — format: evt_{timestamp}_{random4}",
  "type": "string — format: domain:action (e.g., task:assigned, review:rejected)",
  "source": "string — personality slug, 'system', or 'customer'",
  "target": "string|null — personality slug of intended handler",
  "projectId": "string — from state.json",
  "payload": "object — event-type-specific data",
  "priority": "string — CRITICAL | HIGH | MEDIUM | NORMAL | LOW",
  "timestamp": "string — ISO 8601",
  "processed": "boolean — false when created, true after processing",
  "processedAt": "string|null — ISO 8601 when processed",
  "processedBy": "string|null — personality slug or 'system'",
  "generatedEvents": ["string — IDs of events created by processing this one"],
  "parentEventId": "string|null — ID of the event that spawned this one",
  "depth": "integer — recursion depth, root events are 0, max 10"
}
```

---

## 4. risks.json Schema

```json
{
  "risks": [
    {
      "id": "string — format: risk_NNN",
      "title": "string",
      "description": "string",
      "category": "string — technical | dependency | timeline | scope | security | compliance",
      "likelihood": "string — high | medium | low",
      "impact": "string — high | medium | low",
      "status": "string — open | mitigated | accepted | closed",
      "mitigation": "string — proposed or applied mitigation",
      "owner": "string — personality slug responsible for tracking",
      "raisedBy": "string — personality slug who identified the risk",
      "raisedAt": "string — ISO 8601",
      "relatedIssues": ["integer — issuetracker issue IDs"]
    }
  ]
}
```

---

## 5. registry.json Schema

Located at `$JWARE_HOME/.jware/registry.json`.

```json
{
  "companyName": "JWare Solutions",
  "totalHeadcount": 48,
  "projects": [
    {
      "projectId": "string — proj_NNN",
      "projectName": "string",
      "projectPath": "string — absolute path",
      "phase": "string — current phase",
      "teams": ["string — lead personality slugs"],
      "pm": "string — personality slug",
      "startedAt": "string — ISO 8601",
      "lastActivity": "string — ISO 8601"
    }
  ],
  "teamUtilization": {
    "personality-slug": {
      "allocated": "boolean",
      "projectId": "string|null",
      "role": "string — job title"
    }
  },
  "lastUpdated": "string — ISO 8601"
}
```

---

## 6. Decision Log Entry Format

Files in `.jware/decisions/` follow this naming: `YYYY-MM-DD-NNN-topic.md`

```markdown
# Decision: [Title]

**Date:** YYYY-MM-DD
**Decided By:** [personality name(s)]
**Related Issues:** #NNN, #NNN

## Context
[What prompted this decision]

## Options Considered
1. **[Option A]** — [description, pros, cons]
2. **[Option B]** — [description, pros, cons]

## Decision
[What was decided and why]

## Dissenters
[Who disagreed and their reasoning, if any]

## Impact
[What changes as a result]
```

---

## 7. Meeting Transcript Format

Files in `.jware/meetings/` follow this naming: `YYYY-MM-DD-topic.md`

```markdown
# Meeting: [Topic]

**Date:** YYYY-MM-DD
**Attendees:** [Names and titles]
**Related Issues:** #NNN, #NNN

## Transcript

**Daniel Kwon:** [dialogue]

**Hannah Reeves:** [dialogue]

**Customer:** [dialogue]

## Decisions Made
- [Decision 1]
- [Decision 2]

## Action Items
- [ ] [Action] — assigned to [personality]
- [ ] [Action] — assigned to [personality]
```

At visibility level 1, meeting files contain only the Decisions Made and Action Items sections.
At visibility level 2, meeting files include a summary paragraph instead of full transcript.
At visibility level 3, meeting files include the full transcript.

---

## 8. Code Review Record Format

Files in `.jware/reviews/` follow this naming: `YYYY-MM-DD-issue-NNN-reviewer.md`

```markdown
# Code Review: Issue #NNN — [Title]

**Reviewer:** [Name] ([personality slug])
**Author:** [Name] ([personality slug])
**Date:** YYYY-MM-DD
**Verdict:** APPROVED | REJECTED | CHANGES_REQUESTED

## Files Reviewed
- [file paths]

## Comments
[In-character review comments]

## Summary
[Overall assessment]
```

---

## 9. Initialization Procedure

When `/jware` creates a new project engagement:

1. **Create directory structure:**
```
.jware/
  state.json
  events.json
  risks.json
  decisions/
  meetings/
  reviews/
```

2. **Initialize state.json** — copy from template at `$JWARE_HOME/templates/project-state.json`, fill in project-specific values.

3. **Initialize events.json** — start with an empty array `[]`, then seed with kickoff events.

4. **Initialize risks.json** — copy from template at `$JWARE_HOME/templates/risks.json`.

5. **Create subdirectories** — `decisions/`, `meetings/`, `reviews/` as empty directories (create a `.gitkeep` in each).

6. **Update central registry** — read `$JWARE_HOME/.jware/registry.json`, add the new project, update team utilization, write back.

7. **Initialize .jware/issues** — if `.jware/issues/` doesn't exist in the project, run `bash $JWARE_HOME/scripts/jware-issue.sh init "$PROJECT_DIR" "$PROJECT_NAME"`. Set reviewers to the assigned dev lead, QA lead, and PM.

---

## 10. Phase Transitions

| Current Phase | Transitions To | Trigger |
|--------------|---------------|---------|
| `intake` | `kickoff` | Intake meeting complete, scope approved |
| `kickoff` | `development` | Dev lead has reviewed scope and created development plan |
| `development` | `development` | Normal work cycle (stays in development) |
| `development` | `blocked` | Decision needed from customer, no workaround |
| `development` | `review` | All issues complete, final review cycle |
| `blocked` | `development` | Customer provides verdict, blocker resolved |
| `review` | `development` | Final review finds issues, more work needed |
| `review` | `delivery` | Final review and QA pass |
| `delivery` | `completed` | Customer accepts delivery |
| `completed` | (terminal) | Project done, teams freed |

Phase transitions are recorded as events (`project:phase-change`) and logged in the decision log.

---

## 11. Atomic Write Protocol

All state file modifications MUST follow this protocol:

1. **Read** the current file contents
2. **Modify** in memory
3. **Write** the complete file using the Write tool (which overwrites atomically)
4. **Never** partially write a file or append to JSON arrays in place

For `.jware/issues` files, use `$JWARE_HOME/scripts/jware-issue.sh` — it handles atomic writes internally.

---

## 12. Project Cleanup

When a project reaches the `completed` phase:

1. Update `.jware/state.json` — set phase to `completed`, record completion timestamp
2. Update central registry — set team members' `allocated` to `false`, `projectId` to `null`
3. Do NOT delete `.jware/` — it serves as a historical record
4. Do NOT close issuetracker issues automatically — the customer decides what to close

---

## 13. State Recovery

If state files are corrupted or missing:

| Problem | Recovery |
|---------|----------|
| `state.json` missing | Cannot recover — tell user to re-run `/jware` |
| `events.json` missing | Create empty array `[]`, warn user that event history is lost |
| `risks.json` missing | Create empty risks template |
| `decisions/` missing | Create empty directory |
| `meetings/` missing | Create empty directory |
| `reviews/` missing | Create empty directory |
| `registry.json` missing | Create fresh registry from template |
| Corrupted JSON | Attempt to parse; if failed, backup the corrupted file as `.bak` and recreate from template |
