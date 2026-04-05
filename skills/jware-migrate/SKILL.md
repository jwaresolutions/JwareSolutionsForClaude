---
name: jware-migrate
description: "One-time migration — converts existing project state to the cascading agent architecture (v2)"
---

# JWare Solutions — Migration to Cascading Agent Architecture

## Trigger

`/jware-migrate` from a project directory with `.jware/` present.

## Prerequisites

1. Run: `bash $JWARE_HOME/scripts/jware-state-check.sh "$(pwd)"`
   - If not OK, stop with error.
2. Check `.jware/migrated-v2.json` — if exists: "Already migrated. No action needed." Stop.
3. Confirm with user before proceeding (one-way migration).

## Step 1: Snapshot

```bash
cp -r .jware .jware-pre-migration-backup
```

Read all state: `state.json`, `events.json`, `projects/{id}/project.json`, `.jware/issues/issues/*.json`.

## Step 2: Map Tasks to Teams

For every open issue (status not `done` or `closed`), determine team assignment.

Use `engine/roster.md` for team membership. Assignment signals:

| Signal | Team |
|--------|------|
| Labels: `backend`, `api`, `data`, `database` | Alpha |
| Labels: `frontend`, `ui`, `ux`, `design`, `accessibility` | Bravo |
| Labels: `infrastructure`, `devops`, `deployment`, `ci`, `performance` | Charlie |
| Labels: `qa`, `testing`, `bug` (no other team signal) | QA |
| Labels: `trading`, `quant`, `crypto`, `risk` | Trading |
| Assignee on Marcus's team (see roster) | Alpha |
| Assignee on Sarah's team (see roster) | Bravo |
| Assignee on Tomas's team (see roster) | Charlie |
| Assignee on Margaret's team (see roster) | QA |
| Assignee on Richard's team (see roster) | Trading |

Priority if ambiguous: 1) Assignee's team, 2) Most specific label, 3) Default to Alpha.

Add `team` and `teamAgent` fields to each issue:
```json
{ "team": "alpha", "teamAgent": "jware-team-alpha" }
```

Log every assignment to `.jware/migration-log.md`.

## Step 3: Map Assignees to Role Agents

For each open issue, add `roleAgent` and `personalitySlug`:

| Current Activity | Role Agent |
|-----------------|------------|
| Assigned / in_progress | `jware-dev` or `jware-dev-senior` (spike or effort > 2 days = senior) |
| review_pending / in_review | `jware-reviewer` |
| verification_pending | `jware-verifier` |
| qa_pending / qa_in_progress | `jware-qa` |

## Step 4: Restructure Events

For each unprocessed event in `.jware/events.json`:
- Add `team` and `teamAgent` based on the related task
- For agent dispatch events: add `roleAgent` and `personalitySlug`
- Events without task context (lifecycle, decisions): leave without team assignment

## Step 5: Update Configuration

### project.json

Add to `.jware/projects/{projectId}/project.json`:

```json
{
  "architecture": "v2-cascading",
  "teams": {
    "alpha":   { "active": true/false, "lead": "marcus-chen", "tasks": [...] },
    "bravo":   { "active": true/false, "lead": "sarah-kim", "tasks": [...] },
    "charlie": { "active": true/false, "lead": "tomas-rivera", "tasks": [...] },
    "qa":      { "active": true/false, "lead": "margaret-chen", "tasks": [] },
    "trading": { "active": true/false, "lead": "richard-cole", "tasks": [] }
  },
  "devopsApproval": { "status": "grandfathered", "approvedBy": null, "note": "Pre-migration — gate applies to new work only" }
}
```

Set `active: true` only for teams with assigned tasks.

### state.json

Add: `"architecture": "v2-cascading"`, `"migratedAt": "{ISO 8601}"`.

## Step 6: Initialize Jane's Files

**Per-project** (in `.jware/`):
- `jane-observations.md` — initialized with migration note, no prior observations
- `jane-archive.md` — empty
- `agent-context/` — empty directory

**Global** (in `$JWARE_HOME/.jware/jane-global/`):
- `project-index.md` — append new project row (create if missing)
- `lessons-learned.md` — create if missing
- `cross-project-observations.md` — create if missing

## Step 7: Validate

1. Every open issue has `team` and `teamAgent` fields
2. Every agent-dispatch event has `roleAgent` and `personalitySlug`
3. Team assignments match assignee teams (flag mismatches)
4. `state.json` has `architecture: "v2-cascading"`
5. `project.json` has `teams` and `devopsApproval`
6. Jane files exist

## Step 8: Write Marker

Create `.jware/migrated-v2.json`:
```json
{
  "version": "v2-cascading",
  "migratedAt": "{ISO 8601}",
  "tasksTotal": N, "tasksMapped": N,
  "teamsActivated": ["alpha", ...],
  "eventsRestructured": N,
  "validationPassed": true,
  "validationWarnings": []
}
```

## Step 9: Report

```
═══════════════════════════════════════════════
  JWARE MIGRATION — COMPLETE
  Project:      {name}
  Architecture: v2-cascading
═══════════════════════════════════════════════
  Alpha: {N}  Bravo: {N}  Charlie: {N}  QA: {N}  Trading: {N}
  Events restructured: {N}
  Validation: {PASSED / WARNINGS}
  Backup: .jware-pre-migration-backup/
═══════════════════════════════════════════════
```

## Rollback

```bash
rm -rf .jware && mv .jware-pre-migration-backup .jware
```

Manually remove global Jane index entry.
