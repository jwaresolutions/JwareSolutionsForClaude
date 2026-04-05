# State File Schemas

Reference for all JWare state files stored in `.jware/`.

## .jware/state.json

The primary project state file. Written by Jane and intake skill.

```json
{
  "projectId": "proj_{NNN}",
  "projectName": "string",
  "projectPath": "absolute path to project directory",
  "status": "intake | active | paused | completed | cancelled",
  "visibility": 1 | 2 | 3,
  "phase": "intake | scoping | scoping-pending | development | testing | review | delivery | completed",
  "teams": [
    {
      "lead": "full name",
      "leadSlug": "slug",
      "members": [
        { "name": "string", "slug": "string", "role": "Senior Dev | Mid Dev | Junior Dev", "workstream": "string | null" }
      ],
      "qa": [
        { "name": "string", "slug": "string" }
      ]
    }
  ],
  "pm": "PM full name",
  "sa": "Daniel Kwon",
  "startDate": "ISO 8601 date",
  "greenfield": true | false | null,
  "techStack": ["string"],
  "specialDivisions": ["trading"],
  "tradingDivision": true | false,
  "gitStrategy": "single-branch | feature-branches | workstream-branches",
  "currentCycle": 0,
  "completedTasks": 0,
  "totalTasks": 0,
  "blockedTasks": 0,
  "uiTesting": { "hasUI": true, "type": "web", "access": {}, "requiredTools": [], "keyFlows": [] } | null,
  "createdAt": "ISO 8601",
  "updatedAt": "ISO 8601"
}
```

## .jware/auto-state.json

Jane's automation state. Created by `/jware-auto`.

```json
{
  "status": "running | paused-for-input | completed | error",
  "startedAt": "ISO 8601",
  "pausedAt": "ISO 8601 | null",
  "cycleCount": 0,
  "totalEventsProcessed": 0,
  "consecutiveEmptyCycles": 0,
  "maxCycles": 50,
  "pauseReason": "string | null",
  "exitCode": "string | null",
  "decisionsBlocking": [],
  "lastCycleAt": "ISO 8601 | null"
}
```

## .jware/risks.json

Daniel's risk register. Populated during scoping.

```json
{
  "projectId": "proj_{NNN}",
  "assessedBy": "daniel-kwon",
  "assessedAt": "ISO 8601 | null",
  "risks": [
    {
      "id": "risk_{NNN}",
      "title": "string",
      "description": "specific technical detail",
      "category": "technical | integration | scope | timeline | resource | security | dependency",
      "likelihood": "low | medium | high",
      "impact": "low | medium | high | critical",
      "mitigation": "specific mitigation strategy",
      "owner": "personality slug",
      "status": "open | mitigated | realized | closed",
      "relatedIssues": ["int"],
      "identifiedAt": "ISO 8601"
    }
  ]
}
```

## .jware/decisions/{issueId}-{slug}.json

Decision records created during meetings.

```json
{
  "id": "int — issue ID",
  "title": "issue title",
  "decidedAt": "ISO 8601",
  "decidedBy": "customer",
  "verdict": "approve | reject | defer",
  "rationale": "customer's stated reason",
  "alternatives": "other options on the table",
  "impact": "what this enables or blocks",
  "meetingRef": ".jware/meetings/{filename}"
}
```

## Atomic Write Protocol

All state file writes MUST be atomic:
1. Read the current file
2. Modify in memory
3. Write the complete file (overwrite atomically)
4. Never partially write or append to JSON in place

For issue files, use `$JWARE_HOME/scripts/jware-issue.sh` which handles atomic writes internally.
