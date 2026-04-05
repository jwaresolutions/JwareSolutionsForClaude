---
name: jware-dashboard
description: "Company-wide monitoring across all active projects (run from JwareSolutions directory only)"
---

# JWare Solutions — Company Dashboard

## Trigger

`/jware-dashboard` or `/jware-dashboard [1|2|3]` from the JwareSolutions directory. READ-ONLY — modifies no files.

## Prerequisites

Verify the central registry exists:
```bash
test -f $JWARE_HOME/.jware/registry.json
```

If missing: "The dashboard must be run from the JwareSolutions directory. For per-project status, use `/jware-status`."

## Visibility Level

- If user provided a number: use it. Default: **Level 2**.
- Valid: `1`, `2`, `3`. Anything else defaults to `2`.

## Load Data

### Registry

Read `$JWARE_HOME/.jware/registry.json`. Include `active` and `paused` projects. Exclude `completed` (unless explicitly requested).

If empty or missing: "No active JWare engagements found. Use `/jware` to start a project."

### Per-Project Data

For each project, run in parallel:
- `bash $JWARE_HOME/scripts/jware-state-check.sh "{projectPath}"` — state summary
- `bash $JWARE_HOME/scripts/jware-task-counts.sh "{projectPath}"` — task counts
- Read `.jware/events.json` — pending events

For Level 2+: also read `.jware/decisions/`, `.jware/reviews/`
For Level 3: also read `.jware/meetings/`, `.jware/events.json` fully

**Error handling:** One broken project never blocks others.

| Problem | Treatment |
|---------|-----------|
| Path doesn't exist | `[NOT FOUND]` — suggest registry cleanup |
| state.json missing | `[STATE ERROR]` — continue with others |
| issues/ missing | Show counts as `N/A` |

### Team Utilization

From each project's `state.json` team assignments:
- Track which members are on which projects
- 1 project = 100%, 2 projects = 50%/50%
- Unallocated = zero assignments

## Level 1 — Executive Overview

```
================================================================
  JWARE SOLUTIONS — OPERATIONS DASHBOARD
  {date}
================================================================
  Active Projects:      {N}
  Team Utilization:     {X}%
  Pending Decisions:    {N} (across all projects)
================================================================

PROJECT: {name}                           [{status}]
  Phase:    {phase}
  Progress: {done}/{total} done | {inProgress} active | {blocked} blocked | {decisions} decisions
  Teams:    {devLead}, {pm}
  {If blocked: "Blockers: {brief}"}
  {If decisions: "Decisions: {issue IDs}"}

----------------------------------------------------------------
{Repeat for each project}

================================================================
TEAM STATUS
  Marcus Chen (Alpha):   {project} ({pct}%)
  Sarah Kim (Bravo):     {project} ({pct}%)
  Tomas Rivera (Charlie):{project} ({pct}%)
  Unallocated:           {names or "None"}
================================================================
```

Rules: one block per project (max 5 lines), blockers/decisions only if present.

## Level 2 — Working Detail

Everything from Level 1, then per project:

- **TASK BREAKDOWN** — progress bar + all counts
- **RECENT COMPLETIONS (last 5)** — `#{id}: {title} — {assignee}. {review outcome}.`
- **KEY DECISIONS (last 5)** — `[{date}] #{id}: {title} — {verdict}`
- **BLOCKERS** — `#{id}: {title} — Reason: {why}`
- **DECISIONS PENDING** — `#{id}: {title} — raised by {who}`

After all projects:

- **CROSS-PROJECT DEPENDENCIES** — if any project's issue depends on another project
- **RESOURCE CONFLICTS** — people split across projects
- **RECENT EVENTS (last 10)** — `[{time}] {project}: {type} — {summary}`
- **FULL TEAM UTILIZATION** — every person with project assignments

## Level 3 — Full Transparency

Everything from Level 2, then per project:

- **EVENT LOG** — last 20 unprocessed + last 10 processed
- **MEETING TRANSCRIPTS** — last 24 hours, full content
- **CODE REVIEW ACTIVITY** — full detail with findings
- **INTERNAL DISCUSSIONS** — significant events with personality-driven attribution from `engine/roster.md` personality file paths. Full interpersonal dynamics visible.

## Visual Ordering

Projects ordered by urgency:
1. Blocked (any blocked issues) — first
2. Active — Development phase
3. Active — Testing/QA phase
4. Active — Scoping phase
5. Paused — last among included
6. Error/Not Found — bottom with warning

Within each tier, alphabetical by name.

## Read-Only Enforcement

This skill writes to **nothing**. Zero files. No exceptions.
