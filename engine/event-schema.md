# Event Schema Reference

Events are stored in `.jware/events.json` as an array. Each event follows this base schema.

## Base Event Schema

```json
{
  "id": "evt_{uuid}",
  "type": "string — event type (see below)",
  "source": "string — who/what generated this event (slug or 'system' or 'customer')",
  "target": "string | null — who this event is directed at",
  "projectId": "string — proj_{NNN}",
  "payload": { "...event-type-specific fields..." },
  "priority": "HIGH | MEDIUM | LOW",
  "timestamp": "ISO 8601",
  "processed": false,
  "processedAt": null,
  "processedBy": null,
  "generatedEvents": [],
  "parentEventId": "string | null — parent event that caused this one",
  "depth": 0
}
```

## Common Event Types

### Project Lifecycle
- `project:intake` — customer submits a project
- `project:scoping` — Daniel completes technical assessment
- `project:kickoff` — scoping approved, development begins
- `project:phase-change` — phase transition (e.g., development → review)

### Tasks
- `task:assigned` — task assigned to a developer
- `task:started` — developer begins work
- `task:completed` — developer reports completion
- `task:blocked` — task is blocked by a dependency

### Reviews & QA
- `review:requested` — code review requested
- `review:completed` — reviewer submits verdict
- `qa:requested` — QA testing requested
- `qa:completed` — QA submits results
- `verify:requested` — JARVIS verification requested
- `verify:completed` — JARVIS reports results

### Decisions
- `decision:needed` — JWare needs customer input
- `verdict:received` — customer renders a decision

### Meetings
- `meeting:action-item` — action item from a meeting

## Payload Examples

### meeting:action-item
```json
{
  "meetingFile": ".jware/meetings/{filename}",
  "actionItem": "description of the action",
  "issueId": "int | null",
  "dueDate": "ISO 8601 | null"
}
```

### verdict:received
```json
{
  "decisionId": "int — issue ID",
  "originalQuestion": "issue title",
  "verdict": "approve | reject | defer",
  "customerNotes": "stated rationale",
  "meetingFile": ".jware/meetings/{filename} | null"
}
```

### task:assigned
```json
{
  "issueId": "int",
  "title": "issue title",
  "priority": "high | medium | low",
  "assignedTo": "developer slug | null",
  "workstream": "string | null",
  "blockedBy": ["int — issue IDs"],
  "estimatedEffort": "string"
}
```

## Rules

- Always generate a UUID for event `id` (format: `evt_{uuid}`)
- Always use ISO 8601 UTC timestamps
- Set `depth` based on parent chain: root events = 0, child events = parent.depth + 1
- Append events to the `events` array in `.jware/events.json`
- Mark events as `processed: true` after Jane handles them (set `processedAt` and `processedBy`)
