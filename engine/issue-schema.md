# Issue Tracker JSON Schema

Issue data lives at `<project-dir>/.jware/issues/`.

## Directory Structure

```
.jware/issues/
  config.json                    — tracker config
  issues/{id:03d}.json           — individual issues (001.json, 012.json)
  projects/{id:03d}.json         — issue grouping projects
  assets/{issue_id}/             — issue attachments
```

## config.json

```json
{
  "name": "string — display name",
  "nextIssueId": "int — next ID to allocate",
  "nextProjectId": "int — next project ID to allocate",
  "reviewers": ["PM", "Dev Lead", "Security"]
}
```

## issues/{id:03d}.json

```json
{
  "id": "int",
  "title": "string",
  "description": "string",
  "status": "open | in_progress | done | closed",
  "priority": "high | medium | low",
  "labels": ["string"],
  "projectId": "int | null",
  "cycle": "int | null",
  "personas": ["string"],
  "files": ["string — relative file paths"],
  "blockedBy": ["int — IDs of blocking issues"],
  "reviews": {
    "{reviewer}": { "verdict": "approve | defer | reject | null", "notes": "string" }
  },
  "userVote": { "verdict": "approve | defer | reject | null", "notes": "string" },
  "createdAt": "ISO 8601",
  "updatedAt": "ISO 8601"
}
```

## projects/{id:03d}.json

```json
{
  "id": "int",
  "name": "string",
  "description": "string",
  "status": "active | completed | archived",
  "createdAt": "ISO 8601"
}
```

## Dependency Rules

- `blockedBy` creates directed edges: issue is blocked BY the listed IDs
- Adding a blockedBy entry triggers DFS cycle detection — cycles are rejected
- Deleting an issue cleans all blockedBy references to it across other issues
