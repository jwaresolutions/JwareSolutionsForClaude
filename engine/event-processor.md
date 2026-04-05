# Engine Module: Event Processor

**Purpose:** Defines the event processing loop mechanics -- how events are read, prioritized, processed, and how new events are generated. This module is consumed by any skill or process that runs the engine's event loop (primarily `/jware-auto`).

---

## 1. How to Read events.json

### File Location

Per-project event queue:
```
{projectRoot}/.jware/events.json
```

### File Schema

```json
{
  "events": [
    {
      "id": "evt_a7f3b2c1-4e5d-4a8b-9c1e-2f3a4b5c6d7e",
      "type": "review:rejected",
      "source": "margaret-chen",
      "target": null,
      "projectId": "proj_001",
      "payload": {},
      "priority": "MEDIUM",
      "timestamp": "2026-03-24T14:32:00.000Z",
      "processed": false,
      "processedAt": null,
      "processedBy": null,
      "generatedEvents": [],
      "parentEventId": null,
      "depth": 0
    }
  ]
}
```

### Reading Pending Events

To get the list of events that need processing:

```
1. Read events.json
2. Filter: events where processed == false
3. These are the pending events
```

Events with `processed: true` remain in the file as short-term reference but are periodically moved to `processed-events.json` for archival.

---

## 2. Priority Ordering

Events are processed in **priority-then-timestamp** order. Higher priority events are always processed before lower priority events, regardless of when they were created.

### Priority Levels

| Priority | Level | Examples |
|----------|-------|---------|
| `CRITICAL` | 1 (highest) | Security breach, critical QA failure, full blocker, data loss risk |
| `HIGH` | 2 | Blocker raised, review loop (3+ rejections), customer decision received, scope risk |
| `MEDIUM` | 3 | Task completed, review requested, QA requested, decision needed |
| `NORMAL` | 4 | Task assigned, task started, milestone reached, conflict internal |
| `LOW` | 5 (lowest) | Task created, non-blocking suggestions, tech debt identified, informational events |

### Sorting Algorithm

```
FUNCTION sortEvents(pendingEvents):
  1. Define priority order: CRITICAL=1, HIGH=2, MEDIUM=3, NORMAL=4, LOW=5
  2. Sort by priority (ascending -- lower number = higher priority)
  3. Within the same priority, sort by timestamp (ascending -- oldest first)
  4. Return sorted list
```

**Example:** Given these pending events:

```
evt_001: priority=MEDIUM,   timestamp=2026-03-24T10:00:00Z  (task:completed)
evt_002: priority=HIGH,     timestamp=2026-03-24T10:05:00Z  (blocker:raised)
evt_003: priority=MEDIUM,   timestamp=2026-03-24T10:02:00Z  (review:requested)
evt_004: priority=CRITICAL, timestamp=2026-03-24T10:10:00Z  (security:issue_found)
```

Processing order: `evt_004` (CRITICAL) -> `evt_002` (HIGH) -> `evt_001` (MEDIUM, older) -> `evt_003` (MEDIUM, newer).

---

## 3. The Processing Loop

### Main Algorithm

```
FUNCTION processEventQueue(projectRoot):

  SET eventsProcessed = 0
  SET cycleDepth = 0
  SET maxEventsPerCycle = 50
  SET maxDepth = 10

  LOOP:
    1. READ events.json from {projectRoot}/.jware/events.json
    2. FILTER pending events (processed == false)
    3. IF no pending events: BREAK (queue is empty)
    4. IF eventsProcessed >= maxEventsPerCycle: BREAK (cycle limit reached)

    5. SORT pending events by priority then timestamp (Section 2)

    6. FOR EACH event in sorted pending events:
       a. IF eventsProcessed >= maxEventsPerCycle: BREAK
       b. IF event.depth >= maxDepth: MARK event as failed
          - Set error: "Maximum recursion depth exceeded"
          - CONTINUE to next event

       c. MARK event as processing:
          - Set processed = true (tentative)
          - Set processedAt = current ISO 8601 timestamp

       d. LOOK UP process rule for event.type
          - Process rules are defined in the event-engine.md architecture document
          - Each event type has a specific process rule

       e. EXECUTE the process rule:
          - This may dispatch personality agents
          - This may write to issuetracker
          - This may update state files
          - This may generate new events

       f. COLLECT generated events from the process rule execution

       g. FOR EACH generated event:
          - Assign a new event ID: evt_ + UUID
          - Set parentEventId = current event's ID
          - Set depth = current event's depth + 1
          - Set processed = false
          - Set timestamp = current ISO 8601 timestamp
          - APPEND to events.json

       h. UPDATE the current event:
          - Set processed = true (confirmed)
          - Set processedAt = current ISO 8601 timestamp
          - Set processedBy = the personality or "system" that handled it
          - Set generatedEvents = list of generated event IDs

       i. INCREMENT eventsProcessed

    7. WRITE updated events.json (atomic write)
    8. CONTINUE LOOP (process newly generated events)

  END LOOP

  9. MOVE all processed events to processed-events.json (append, do not overwrite)
  10. CLEAN events.json: remove processed events, keep only pending
  11. UPDATE .jware/state.json with current project phase and status
  12. RETURN processing summary
```

### Step-by-Step Walkthrough

**Step 1-2: Read and filter.** Load the event queue and identify unprocessed events.

**Step 3: Empty check.** If nothing is pending, the cycle is done. This is the normal termination condition.

**Step 4: Cycle limit check.** Safety valve -- prevents runaway processing. If the limit is hit, remaining events stay in the queue for the next `/jware-auto`.

**Step 5: Sort.** Critical events before high, high before medium, etc. Within priority, oldest first (FIFO within tier).

**Step 6a-b: Per-event guards.** Check cycle limit and recursion depth before processing each event.

**Step 6c: Mark processing.** Tentatively mark the event so a crash during processing does not cause reprocessing on resume (the event is already marked). If processing fails, it will be marked as `failed` instead.

**Step 6d-e: Execute process rule.** This is where the actual work happens -- agents are dispatched, files are written, decisions are made. Process rules are defined per event type in the event engine architecture.

**Step 6f-h: Handle generated events.** New events produced by processing are appended to the queue with incremented depth and a parent pointer. They will be picked up in the next iteration of the loop.

**Step 7: Atomic write.** The updated events.json is written atomically (write to temp file, fsync, rename) to prevent corruption.

**Step 8: Loop.** The outer loop re-reads and re-sorts, picking up newly generated events. This continues until the queue is empty or limits are hit.

**Step 9-11: Cleanup.** After the loop completes, processed events are archived, the queue is cleaned, and state is updated.

---

## 4. Recursion Limits

### Maximum Depth: 10

Every event has a `depth` field. Root events (user-initiated or system-generated at the top level) have depth 0. Events generated by processing a depth-N event have depth N+1.

**If an event has depth >= 10, it is NOT processed.** It is marked as `failed` with the error `"Maximum recursion depth exceeded"`. This prevents infinite chains.

**Example chain:**
```
depth 0: project:intake (user submits project)
depth 1: project:scoping (generated by intake processing)
depth 2: project:kickoff (generated by scoping processing)
depth 3: task:created (generated by kickoff processing)
depth 4: task:assigned (generated by task creation)
depth 5: task:started (developer picks up task)
depth 6: task:completed (developer finishes)
depth 7: review:requested (generated by completion)
depth 8: review:passed (reviewer approves)
depth 9: qa:requested (generated by review pass)
depth 10: BLOCKED -- would not process in this cycle
```

Depth-10 events remain in the queue as pending and will be processed in the NEXT `/jware-auto` cycle at depth 0 (their depth is reset when they become root events of a new cycle).

### Maximum Events Per Cycle: 50

No single processing cycle processes more than 50 events. This prevents:
- Unbounded resource consumption in a single session
- A large project generating hundreds of events that consume all available context
- Runaway cascades from misconfigured process rules

Events beyond the limit remain pending and are processed in subsequent cycles.

---

## 5. Event ID Generation

Every event receives a unique identifier at creation time.

### Format

```
evt_{uuid}
```

**Prefix:** `evt_` (literal string)
**UUID:** Standard UUID v4 (e.g., `a7f3b2c1-4e5d-4a8b-9c1e-2f3a4b5c6d7e`)

### Generation Rule

```
FUNCTION generateEventId():
  RETURN "evt_" + uuidv4()
```

IDs are assigned at creation time and never change. They are used for:
- `parentEventId` references (tracing causality)
- `generatedEvents` arrays (tracking what an event produced)
- `blockerEventId` references (linking blockers to their cause)
- Audit trail in processed-events.json

---

## 6. Failed Event Handling

When an event cannot be processed successfully, it is marked as failed rather than retried indefinitely.

### Failure Conditions

| Condition | Action |
|-----------|--------|
| Process rule execution throws an error | Mark as `failed`, log error, continue to next event |
| Agent dispatch fails | Mark as `failed`, log error, continue to next event |
| Recursion depth exceeded (depth >= 10) | Mark as `failed`, log error `"Maximum recursion depth exceeded"`, continue |
| Missing process rule for event type | Mark as `failed`, log error `"Unknown event type: {type}"`, continue |
| Required payload fields missing | Mark as `failed`, log error `"Invalid payload: missing {field}"`, continue |

### Failed Event Schema

```json
{
  "id": "evt_...",
  "type": "task:started",
  "processed": true,
  "processedAt": "2026-03-24T14:35:00.000Z",
  "status": "failed",
  "error": "Agent dispatch failed: personality file not found for slug 'unknown-person'",
  "generatedEvents": []
}
```

### Recovery

Failed events are moved to `processed-events.json` with their error logged. They are not automatically retried. To retry a failed event:

1. Read the failed event from `processed-events.json`
2. Create a new event with the same type and payload
3. Assign a new event ID
4. Set depth to 0 (fresh start)
5. Append to `events.json`

This manual retry ensures that transient failures do not cause infinite retry loops.

---

## 7. Infinite Loop Detection and Prevention

### Detection Signals

| Signal | Threshold | Action |
|--------|-----------|--------|
| Same event type generated by its own type | 3 occurrences in a chain | Log warning, mark deepest as failed |
| Cycle between two event types (A generates B, B generates A) | 4 round-trips | Log warning, break cycle by marking as failed |
| Total events generated in one cycle | >50 | Hard stop, remaining events stay pending |
| Depth limit reached | depth >= 10 | Hard stop for that chain |
| Same task ID appearing in >6 consecutive events | 6 events | Log warning, dispatch dev lead for assessment |

### Prevention Rules

1. **Review-rejection loops.** If `review:rejected` fires 3+ times on the same task, a `conflict:internal` event is generated instead of another `task:assigned`. If rejections reach 5, a `blocker:raised` is generated. This breaks the review loop.

2. **QA-failure loops.** If `qa:failed` fires 3+ times on the same task, the dev lead is dispatched to assess whether the task needs a different approach or developer. This may produce `task:reassigned`.

3. **Decision loops.** If `decision:needed` fires for the same question twice, the second instance is deduplicated. The engine checks existing pending decisions before creating a new one.

4. **Depth ceiling.** Events at depth 10 are unconditionally stopped. They remain in the queue for the next cycle but reset to depth 0.

5. **Cycle limit.** The 50-event-per-cycle limit ensures that even in pathological cases, the engine stops and returns control.

### Loop Detection Algorithm

```
FUNCTION detectLoop(currentEvent, eventHistory):
  1. Build the ancestry chain:
     - Walk parentEventId pointers back to the root
  2. Count occurrences of currentEvent.type in the ancestry chain
  3. IF count >= 3 AND the type is generating itself:
     RETURN "self-referential loop detected"
  4. Check for A->B->A cycles:
     - Look at the last 8 events in the chain
     - If the same pair of types alternates 4+ times, it is a cycle
     RETURN "type cycle detected"
  5. Check for task ID repetition:
     - If the same taskId appears in >6 consecutive events in the chain
     RETURN "task stuck in loop"
  6. RETURN null (no loop detected)
```

When a loop is detected, the event is marked as `failed` with the loop description as the error message, and a `blocker:raised` event is generated to surface the problem.

---

## 8. Events and the Issuetracker

Events interact with the issuetracker in two directions: events CREATE and UPDATE issues, and issue state changes GENERATE events.

### Events that Create Issues

| Event Type | Issue Created | Labels |
|------------|--------------|--------|
| `project:intake` | Project registered in issuetracker | -- |
| `project:scoping` | "Scoping: {title}" assigned to Daniel Kwon | -- |
| `task:created` | Task issue with title, description, acceptance criteria | Team label, type label |
| `bug:found` | Bug issue with description, severity | `bug`, severity label |
| `debt:identified` | Tech debt issue | `tech-debt` |
| `scope:risk` | Scope risk issue | `scope-risk`, possibly `decision-needed` |
| `decision:needed` | Decision issue with question and options | `decision-needed` |
| `blocker:raised` | Blocker issue | `blocker` |
| `qa:failed` | Bug issues for each defect found | `qa-failure`, `bug` |
| `qa:passed` (with non-blocking issues) | Minor issue per non-blocking finding | `chore` or `bug` (low severity) |
| `qa:requested` (tool unavailable) | Decision issue for missing QA tools | `decision-needed`, `qa` |

### Events that Update Issues

| Event Type | Issue Update |
|------------|-------------|
| `task:assigned` | Set assignee, status to `assigned` |
| `task:started` | Status to `in_progress` |
| `task:completed` | Status to `review_pending`, add PR summary comment |
| `verify:requested` | Status to `verification_pending`, JARVIS comment posted |
| `verify:passed` | Status to `review_pending`, JARVIS comment updated with "Cleared for review." |
| `verify:failed` | Status to `in_progress` (if attempt < 3), JARVIS failure comment posted |
| `review:requested` | Status to `in_review` |
| `review:passed` | Status to `qa_pending`, add approval comment |
| `review:rejected` | Status to `in_progress`, add rejection comments |
| `qa:requested` | Status to `qa_in_progress` |
| `qa:passed` | Status to `done` |
| `qa:failed` | Status to `in_progress`, add defect report comment |
| `decision:received` | Mark decision issue as `resolved`, add verdict |
| `blocker:resolved` | Mark blocker issue as `resolved` |
| `conflict:resolved` | Add resolution comment to related issue |
| `project:completed` | Close all project issues |

### Issue State Changes that Generate Events

When `/jware-auto` runs, it scans the issuetracker for changes made by the customer:

| Issue Change | Generated Event |
|-------------|-----------------|
| `userVote: approve` on a `decision-needed` issue | `decision:received` with verdict `approve` |
| `userVote: reject` on a `decision-needed` issue | `decision:received` with verdict `reject` |
| `userVote: defer` on a `decision-needed` issue | `decision:received` with verdict `defer` |
| Customer adds a comment to an issue | Informational -- no event generated, but context is available to agents |

---

## 9. Agent Dispatch from Events

When a process rule requires dispatching a personality agent, the event processor coordinates with the personality loader.

### Dispatch Protocol

```
FUNCTION dispatchAgent(personalitySlug, agentType, task, context):
  1. LOAD personality using personality-loader module:
     - personality-loader.loadPersonality(slug, agentType, context)
  2. PREPARE agent prompt:
     - Personality injection block (from loader)
     - Task instructions (from the event's process rule)
     - Project context (from .jware/state.json)
     - Relevant issuetracker issues
     - Codebase access (if developer or reviewer agent)
  3. DISPATCH the agent
  4. COLLECT agent output:
     - Code changes (if developer)
     - Review comments and verdict (if reviewer)
     - Test results and verdict (if QA)
     - Meeting transcript (if meeting participant)
     - Decision and rationale (if lead/manager)
  5. GENERATE follow-up events based on agent output
  6. RETURN agent output for rendering at the project's visibility level
```

### Agent Types by Event

| Event Type | Agent Type | Personality |
|------------|-----------|-------------|
| `task:started` | developer | The assigned developer |
| `review:requested` | reviewer | The assigned reviewer |
| `qa:requested` | qa | The assigned QA engineer |
| `meeting:requested` | meeting | All attendees |
| `conflict:internal` | lead | The mediating dev lead or CTO |
| `project:scoping` | lead | Daniel Kwon (SA) |
| `project:kickoff` | lead | The assigned dev lead |
| `decision:needed` | lead | The assigned PM (framing the question) |
| `blocker:raised` | lead | Ben Hartley (timeline impact) + dev lead (mitigation) |
| `verify:requested` | verifier | JARVIS (system) |
| `qa:requested` (Phase 2) | ux-tester | Selected panelists from UX test panel |

### JARVIS Dispatch (Special Case)

JARVIS (`jware-verifier`) does not use the personality loader. It is dispatched directly:

1. PREPARE agent prompt:
   - Project path and tech stack
   - Task branch and changed files
   - Coverage threshold from project config
   - Attempt number (for escalation tracking)
2. DISPATCH agent: `subagent_type: "jware-verifier"`, `model: "sonnet"`
3. COLLECT structured output: verdict, checks object, voice line
4. POST results as issuetracker comment
5. GENERATE follow-up event: `verify:passed` or `verify:failed`

### UX Test Panel Dispatch (Special Case)

UX test panelists are NOT JWare employees. They are external working professionals dispatched for user perspective testing. They use the personality-loader with the `ux-tester` template.

1. QA Lead (Margaret Chen) selects 2-3 panelists based on task type
2. FOR EACH selected panelist:
   a. LOAD personality using personality-loader with `ux-tester` template
   b. PREPARE prompt with:
      - Full personality profile
      - Plain-language task description (NOT acceptance criteria)
      - UI access instructions from uiTesting config
   c. DISPATCH agent: subagent_type "jware-dev", model "sonnet"
   d. COLLECT panelist report: what they tried, where they got stuck, screenshots
3. POST each panelist's report as an issuetracker comment
4. IF any panelist could not complete the task: verdict is FAILED
5. GENERATE `qa:passed` or `qa:failed` based on combined Phase 1 + Phase 2 results

---

## 10. State Update Protocol

After each processing cycle completes, the following state files are updated:

### 1. events.json

- All processed events removed (moved to archive)
- Only pending events remain
- Atomic write

### 2. processed-events.json

- All newly processed events appended (including failed events)
- Never modified once written -- append-only
- Atomic write

### 3. .jware/state.json

Updated fields:
- `phase`: May change if a phase transition event was processed (e.g., `scoping` -> `development`)
- `status`: May change (e.g., `active` -> `paused` if a pause event was processed)
- `updatedAt`: Always updated to current timestamp

### 4. .jware/projects/{projectId}/ subdirectories

Process rules may write to:
- `tasks/{taskId}.json` -- task records
- `reviews/{taskId}-{timestamp}.json` -- review records
- `qa/{taskId}.json` -- QA records
- `decisions/{id}-{slug}.json` -- decision records
- `meetings/{timestamp}-{topic}.md` -- meeting transcripts
- `milestones/{index}.json` -- milestone records
- `blockers/{id}.json` -- blocker records
- `conflicts/{id}.json` -- conflict records

### 5. Central Registry

Updated via the team-allocator module when:
- A new project is registered (intake)
- Team allocation changes
- A project completes (resources released)
- Capacity changes during the project lifecycle

### Write Safety

All state file writes use atomic operations:

```
1. Write content to a temporary file in the same directory
2. fsync the temporary file
3. Rename (atomic move) the temporary file over the target
```

This guarantees:
- A crash during write leaves the old file intact
- No reader ever sees a partially-written file
- Concurrent sessions reading the same file always get a complete, consistent state

---

## 11. Processing Cycle Summary Output

After the processing loop completes, produce a summary for the user at the project's configured visibility level (see visibility-renderer module).

### Summary Contents

```
FUNCTION produceCycleSummary(processedEvents, projectState, visibilityLevel):
  1. GROUP processed events by category:
     - Project lifecycle events
     - Task lifecycle events
     - Review events
     - QA events
     - Decision/escalation events
     - Scope events
  2. FOR EACH category with events:
     - Render output at the configured visibility level
     - Use visibility-renderer module templates
  3. APPEND any pending decisions that need customer input
     (decision-needed issues are ALWAYS surfaced regardless of visibility level)
  4. APPEND current project status summary
  5. RETURN formatted output
```

The summary is what the user sees when `/jware-auto` completes. It represents everything that happened during this processing cycle, rendered at their preferred level of detail.
