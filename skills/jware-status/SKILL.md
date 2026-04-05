---
name: jware-status
description: "Read-only progress check at visibility level 1 (outcomes), 2 (key decisions), or 3 (full process)"
---

# JWare Solutions — Status

## Trigger

`/jware-status` or `/jware-status [1|2|3]` from a project directory. READ-ONLY except persisting a new visibility level.

## Prerequisites

Run: `bash $JWARE_HOME/scripts/jware-state-check.sh "$(pwd)"`

If not OK, show the error and stop.

## Determine Visibility Level

- If user provided a number: use it AND update `.jware/state.json` `visibilityLevel` field (only write this skill ever does).
- If no number: read `visibilityLevel` from state. Default to `1`.
- Valid: `1`, `2`, `3`. Anything else defaults to `1`.

## Data Gathering

**Always read:**
- State check output (from prerequisites) — projectName, phase, status, pm, auto status
- `bash $JWARE_HOME/scripts/jware-task-counts.sh "$(pwd)"` — all task counts

**For Level 2+, also read:**
- `.jware/decisions/*.json` — recent decisions
- `.jware/risks.json` — risk register
- `.jware/reviews/*.json` — code review outcomes

**For Level 3, also read:**
- `.jware/meetings/` — last 3 meeting transcripts
- `.jware/events.json` — event log

## Auto Mode Status

If `.jware/auto-state.json` exists, show after the Visibility line in the header:

| Status | Display |
|--------|---------|
| `running` | "Auto mode: running (cycle {N}, {N} events processed)" |
| `paused-for-input` | "Auto mode: paused — {reason}" + list blocking decisions |
| `completed` | "Auto mode: completed ({N} cycles, {N} events)" |
| `error` | "Auto mode: error — {reason}" |

If no auto-state.json, show nothing about auto mode.

## Level 1 — Outcomes Only

Compact, clean, under 30 lines. No team names, no internal details.

```
====================================================
  JWARE SOLUTIONS — PROJECT STATUS
====================================================
  Project:      {projectName}
  Phase:        {phase}
  Started:      {startDate}
  Status:       {status}
  Last Updated: {updatedAt}
  Visibility:   Level 1 (Outcomes)
  {Auto Mode line if applicable}
====================================================

  TASK PROGRESS
  ----------------------------------------
  Completed:    {N}
  In Progress:  {N}
  In Review:    {N}
  In QA:        {N}
  Blocked:      {N}
  Total:        {N}
  Progress:     [==========>     ] {X}%

  DECISIONS PENDING: {N}
  {If > 0: list issue IDs}

  NEXT MILESTONE: {name} — Target: {date}

  BLOCKERS: {None or list titles + IDs}
====================================================
```

If decisions pending, append: "Use `/jware-meeting` to discuss or open issues in `.jware/issues/issues/`."

## Level 2 — Key Decisions

Everything from Level 1, then append:

- **COMPLETED** — list each done issue: `#{id}: {title} — By: {assignee} | Review: {verdict}`
- **IN PROGRESS** — `#{id}: {title} — {assignee}`
- **IN REVIEW** — `#{id}: {title} — Reviewer: {name} | Status: {status}`
- **IN QA** — `#{id}: {title} — QA: {name} | Pass/Fail: {outcome}`
- **BLOCKED** — `#{id}: {title} — Reason: {why} — Options: {what}`
- **DECISIONS PENDING** — `#{id}: {title} — Raised by: {who} — Summary: {why}`
- **TEAM** — Dev Lead, Developers, QA, PM
- **RECENT DECISIONS** — from `.jware/decisions/`: date, title, verdict, rationale, impact
- **CODE REVIEW OUTCOMES** — from `.jware/reviews/`: date, title, reviewer, outcome, summary
- **RISK REGISTER** — from `.jware/risks.json`: severity, title, owner, status, mitigation

## Level 3 — Full Internal Process

Everything from Level 2, then append:

- **MEETING TRANSCRIPTS** — last 3 from `.jware/meetings/`, full verbatim content
- **FULL CODE REVIEW DIALOGUE** — re-render reviews with full dialogue
- **EVENT LOG** — from `.jware/events.json`, last 50 chronologically
- **PERSONALITY COMMENTARY** — for significant events, load personality from `engine/roster.md` path, write one sentence of in-character commentary. Base on documented traits only.

## Formatting

- Use `#{id}` zero-padded notation (e.g., `#004`)
- Level 1: no UUIDs, no event IDs, no internal metadata
- Level 2: issue IDs and decision refs, no raw event IDs
- Level 3: full event IDs in event log
- Render per `engine/visibility-renderer.md` guidelines

## Read-Only Enforcement

Reads from: state.json, events.json, auto-state.json, project.json, meetings/, reviews/, decisions/, risks.json, issues/issues/

Writes to: `.jware/state.json` ONLY (visibilityLevel field, only when user provides a number).
