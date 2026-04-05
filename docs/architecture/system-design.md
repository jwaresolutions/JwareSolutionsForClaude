# JWare Solutions -- System Design Specification

**Version:** 1.0
**Date:** 2026-03-24
**Status:** Master Blueprint

---

## Table of Contents

1. [System Overview](#1-system-overview)
2. [Architecture Layers](#2-architecture-layers)
3. [Entry Points](#3-entry-points)
4. [State Management](#4-state-management)
5. [Multi-Session Support](#5-multi-session-support)
6. [Issuetracker Integration](#6-issuetracker-integration)
7. [Greenfield vs Brownfield](#7-greenfield-vs-brownfield)
8. [Personality Loading](#8-personality-loading)
9. [Company Roster](#9-company-roster)
10. [Design Principles](#10-design-principles)

---

## 1. System Overview

JWare Solutions is an event-driven virtual software company simulation built on Claude Code. It is not a chatbot wearing a costume. It is a 48-person organization with reporting chains, interpersonal dynamics, technical opinions, and professional habits -- dispatched as real Claude agents that write real code in real repositories.

### What It Is

A customer (the user) brings a plan for a feature or project. JWare Solutions takes that plan through intake, scoping, team allocation, development, QA, code review, and delivery. Every step is performed by Claude agents loaded with full personality profiles -- their MBTI type, communication style, competencies, Amazon Leadership Principles profile, interpersonal dynamics, and quirks. The agents collaborate, disagree, escalate, and resolve issues the way a real company does, except every interaction is backed by file-based state that persists across sessions.

### What It Produces

- Real code written in the user's real repositories
- Real git branches, commits, and pull requests
- Real code reviews between personality agents
- Real QA test runs with real bug reports
- Real architectural decisions with documented rationale
- Real meeting transcripts reflecting actual personality dynamics

### Scale

| Department | Headcount | Key Roles |
|------------|-----------|-----------|
| C-Suite | 3 | CEO, CTO, COO |
| Engineering | 16 | 3 Dev Leads, 5 Senior Devs, 5 Mid Devs, 3 Junior Devs |
| QA | 3 | 1 QA Lead, 2 QA Engineers |
| DevOps | 2 | 1 DevOps Lead, 1 DevOps Engineer |
| Security | 2 | 1 Security Lead, 1 Security Analyst |
| Design | 3 | 1 Design Lead, 1 UX Designer, 1 Graphic Designer |
| Project Management | 3 | 1 TPM, 2 PMs |
| Solutions Architecture | 1 | Solutions Architect |
| Sales & BD | 2 | 1 Sales Director, 1 BD Rep |
| Marketing & PR | 2 | 1 Marketing Manager, 1 PR Specialist |
| Support | 2 | 1 Support Lead, 1 Support Technician |
| Operations | 3 | 1 Controller, 1 HR Manager, 1 Office Admin |
| Trading Division | 6 | SMD, Quant Analyst, Trading Systems Architect, Crypto/DeFi Specialist, Risk & Compliance Analyst, Domain Expert |
| **Total** | **48** | |

### State Persistence

All state lives in files. There is no in-memory-only state. A session can crash at any point and be resumed from the file system with zero data loss. Two directories form the backbone:

| Directory | Location | Purpose |
|-----------|----------|---------|
| `.jware/` | Per-project (user's repo) | JWare's internal workspace -- team assignments, event queue, decisions, meetings, reviews |
| `.jware/issues/` | Per-project (user's repo) | Shared project board -- the communication and decision interface between JWare and the customer |
| `.jware/` | `JwareSolutions/` repo | Central registry of all active projects and company-wide utilization data |

---

## 2. Architecture Layers

The system is organized into four layers. Each layer has a clear boundary and communicates with adjacent layers through well-defined interfaces.

```
+----------------------------------------------------------+
|  Layer 1 -- Client Interface                              |
|  Entry points: /jware, /jware-auto, /jware-status,   |
|  /jware-meeting, /jware-dashboard                         |
|  Point of contact: PM + Solutions Architect                |
|  Visibility: Levels 1-3                                   |
+----------------------------------------------------------+
         |                    ^
         | events, requests   | status, decisions
         v                    |
+----------------------------------------------------------+
|  Layer 2 -- Company Engine                                |
|  Event processor, process rules, team allocator,          |
|  meeting simulator, conflict resolution                   |
+----------------------------------------------------------+
         |                    ^
         | dispatch orders    | code, reviews, test results
         v                    |
+----------------------------------------------------------+
|  Layer 3 -- Execution Layer                               |
|  Claude agents with personality profiles                  |
|  Real code, real commits, real tests, real reviews        |
+----------------------------------------------------------+
         |                    ^
         | read/write         | read/write
         v                    |
+----------------------------------------------------------+
|  Layer 4 -- State Layer                                   |
|  .jware/ (internal state)                                 |
|  .jware/issues/ (shared project board)                    |
|  JwareSolutions/.jware/registry.json (central registry)   |
+----------------------------------------------------------+
```

### Layer 1 -- Client Interface

The user interacts with JWare Solutions through five entry points (detailed in [Section 3](#3-entry-points)). The interface layer enforces two invariants:

**Point of Contact:** The user's primary contacts are ALWAYS a Project Manager (Hannah Reeves or Jordan Pace) and the Solutions Architect (Daniel Kwon). No other JWare employee initiates direct communication with the customer unless explicitly requested in a meeting. The PM manages the relationship; Daniel manages the technical truth.

**Visibility Levels:** Every interaction respects the project's configured visibility level. The user controls how much of JWare's internal process they see.

| Level | Name | What the User Sees |
|-------|------|--------------------|
| 1 | Outcomes | Task counts, completion percentages, blockers, decisions needed. No internal dynamics. |
| 2 | Key Decisions | Who made which technical decisions and why. Debates that affected the approach. Design tradeoffs. Disagreements that were resolved and how. |
| 3 | Full Process | Complete internal interactions -- meeting transcripts, code review conversations, personality-driven debates, escalation chains, the specific language people used. |

**Decision Mechanism:** The `.jware/issues`'s `userVote` field (with `approve` / `reject` / `defer` verdicts) is the formal decision interface. When JWare needs a customer decision, it creates or updates an issue with the label `decision-needed`. The customer renders a verdict. The engine acts on it.

**Meeting Notes:** When meetings occur (triggered by `/jware-meeting` or internally by the engine), conversation notes are:
1. Saved as full transcripts to `.jware/meetings/`
2. Appended as notes to relevant `.jware/issues` issues (on the appropriate reviewer slot or as general notes)

### Layer 2 -- Company Engine

The engine is the brain of the operation. It reads events, applies company process rules, allocates teams, simulates meetings, and resolves conflicts.

**Event Processor:** Reads `.jware/events.json` and processes events in FIFO order. Each event has a type, payload, and timestamp. Processing an event may generate new events (e.g., processing a `task:ready` event dispatches an agent and generates a `dev:started` event). Processed events are moved to `.jware/processed-events.json` as an audit trail.

**Process Rules:** A mapping from event types to company responses. This is the core behavioral logic -- it defines what JWare does when things happen. Process rules are detailed in a separate Event Engine document; this spec defines the event schema and processing model.

**Team Allocator:** Ben Hartley (TPM) assigns teams based on:

| Factor | How It Affects Allocation |
|--------|--------------------------|
| Project size | Small (1 dev + QA) to large (full team + cross-team) |
| Tech stack | Backend-heavy routes to Marcus's team; frontend-heavy to Sarah's; infra to Tomas's |
| Domain | Trading-related pulls in the Trading Division |
| Current utilization | Checked against `registry.json` team utilization data |
| Greenfield vs brownfield | Greenfield gets more senior allocation; brownfield gets relevant domain experience |

**Meeting Simulator:** Generates interactions between personalities at the project's visibility level. At level 1, meetings produce only outcomes ("the team decided X"). At level 2, they produce key exchanges ("Marcus argued for approach A because of Y; Sarah countered with B; they settled on A with Sarah's modification"). At level 3, they produce full dialogue reflecting each personality's communication style, opinions, and interpersonal dynamics.

**Conflict Resolution:** Follows a strict escalation chain:

```
Developer disagrees with developer
  --> Dev Lead mediates
    --> Dev Leads disagree
      --> CTO (Raj Patel) decides
        --> Technical decision affects scope/timeline
          --> Customer is informed via issuetracker (decision-needed)
```

The engine never deadlocks. If internal resolution fails at any level, it escalates. If it reaches the customer, it surfaces a clear decision with the options considered and JWare's recommendation.

### Layer 3 -- Execution Layer

This is where real work happens. Claude agents are dispatched with personality profiles loaded as system context (see [Section 8](#8-personality-loading)). Each agent:

- **Writes real code** in the user's repository, in the style and with the opinions of their personality
- **Creates real commits** on branches decided by JWare based on project complexity
- **Runs real tests** and reports results back to the engine
- **Conducts real code reviews** -- the reviewer is assigned by the dev lead, and the review reflects the reviewer's personality (Marcus's reviews are detailed and educational; Priya's are fast and direct)
- **Creates real issues** in `.jware/issues` for bugs, tech debt, and blockers found during development

**Git Branching Strategy:** Decided by JWare's dev lead based on project complexity:

| Project Type | Strategy |
|--------------|----------|
| Small feature (1-2 tasks) | Single feature branch off main |
| Medium feature (3-8 tasks) | Feature branch with task branches merged into it |
| Large project (9+ tasks) | Feature branch per workstream, integration branch, merge to main |
| Hotfix | Hotfix branch off main, fast-track review |

**Code Review Flow:**
1. Developer completes work on a branch
2. Dev lead assigns a reviewer (typically a senior dev or peer from the same or adjacent team)
3. Reviewer agent is dispatched with the personality profile and diff
4. Review comments are written to `.jware/reviews/` and relevant issues
5. If changes requested, original developer is re-dispatched
6. Approved code is merged by the dev lead

**QA Flow:**
1. QA agent (assigned during team allocation) is dispatched after code review approval
2. QA agent runs tests, checks coverage, validates acceptance criteria
3. Failures generate issues in `.jware/issues` labeled `qa-failure` with the QA engineer's assessment
4. QA lead (Margaret Chen) sets coverage and quality thresholds per project; agents enforce them

### Layer 4 -- State Layer

All persistent state lives in the file system. There are three state locations:

| Location | Scope | Contents |
|----------|-------|----------|
| `{project}/.jware/` | Per-project | JWare's internal state for this project |
| `{project}/.jware/issues/` | Per-project | Shared project board (issuetracker standard) |
| `JwareSolutions/.jware/registry.json` | Global | Central registry of all active projects |

State details are fully specified in [Section 4](#4-state-management).

---

## 3. Entry Points

### /jware -- New Project Intake

**Invoked from:** The user's project directory
**Input:** A plan document (provided inline, as a file path, or as issuetracker issues)
**Purpose:** Begin a new engagement with JWare Solutions

**What happens:**

1. **Read context.** The engine reads:
   - The plan document
   - Codebase structure (directory tree, package files, config files)
   - Tech stack (detected from package.json, Cargo.toml, go.mod, etc.)
   - Existing `.jware/issues/` (if present -- read for context on past decisions and known issues)
   - Existing git history (branch structure, recent commits, contributors)

2. **Initialize state.** The engine creates:
   - `.jware/` directory with `state.json`, `events.json`, empty subdirectories
   - `.jware/registry-entry.json` for this project
   - Updates `JwareSolutions/.jware/registry.json` to register the new project

3. **Trigger intake event.** A `project:intake` event is pushed to the event queue.

4. **Start intake meeting.** Daniel Kwon (SA) and the assigned PM (Hannah or Jordan, based on current workload) conduct the intake meeting:
   - Daniel reviews the plan for technical feasibility, identifies risks, asks clarifying questions
   - PM establishes timeline expectations, communication preferences, visibility level
   - For brownfield projects, Daniel performs a codebase analysis (tech stack, patterns, debt, test coverage)
   - For greenfield projects, Daniel proposes initial architecture
   - Meeting transcript is saved to `.jware/meetings/`

5. **Produce scoping output.** The intake meeting produces:
   - Updated `state.json` with team assignments, visibility level, phase
   - Issues created in `.jware/issues/` for every scoped work item
   - Any `decision-needed` issues for customer input on scope questions
   - An event for the next phase (`scoping:complete` or `scoping:questions-pending`)

**User sees (by visibility level):**

| Level | Output |
|-------|--------|
| 1 | "Project registered. 12 tasks scoped. 2 questions for you (see issues #3, #7). Development begins after your decisions." |
| 2 | "Daniel reviewed your plan and flagged a risk on the payment integration -- the third-party API doesn't support webhooks, so we'll need a polling strategy. Hannah estimates 3 weeks for the core work. Marcus's team is assigned to backend; Sarah's team handles the frontend. See issues #3 and #7 for two scope decisions we need from you." |
| 3 | Full transcript of the intake meeting including Daniel's technical analysis, the PM's planning notes, and the exact exchange where Daniel identified the API limitation. |

### /jware-auto -- Resume Active Project

**Invoked from:** The user's project directory (must have `.jware/` present)
**Input:** None (reads current state)
**Purpose:** Resume work on an active project

**What happens:**

1. **Read current state.** Load `state.json` and `events.json`.

2. **Check for customer decisions.** Scan `.jware/issues/` for issues labeled `decision-needed` that now have a `userVote` verdict. Each resolved decision generates an event:
   - `approve` --> `decision:approved` event
   - `reject` --> `decision:rejected` event
   - `defer` --> `decision:deferred` event

3. **Process pending events.** Process all events in `events.json` in FIFO order. This may:
   - Dispatch development agents for tasks marked ready
   - Trigger code reviews for completed work
   - Dispatch QA for reviewed code
   - Generate new issues for discovered bugs or tech debt
   - Trigger meetings for decisions that need internal discussion

4. **Surface pending decisions.** If any `decision-needed` issues remain unresolved, surface them to the user.

5. **Report progress.** Show progress at the project's configured visibility level.

**User sees:** Progress report at their visibility level, plus any pending decisions.

### /jware-status [1|2|3] -- Check Progress

**Invoked from:** The user's project directory
**Input:** Optional visibility level override (defaults to project's configured level)
**Purpose:** Read-only progress check -- does not process events or dispatch agents

**Output by level:**

**Level 1:**
```
Project: Trader-X
Status: Active | Phase: Development
Progress: 8 of 14 tasks complete. 2 in review. 1 in QA. 1 blocked.
Blocked: Issue #23 needs your decision (scope question on real-time data refresh).
Next: 2 tasks ready to start once #23 is resolved.
```

**Level 2:**
```
Project: Trader-X
Status: Active | Phase: Development

Completed (8):
  - #1-#5: Core API endpoints (Marcus's team). Merged to feature/api.
  - #6-#7: Auth integration (Priya). Merged after Derek's review caught a token refresh edge case.
  - #8: Database migrations (Liam). Clean pass.

In Review (2):
  - #9: WebSocket layer (Priya). Reviewer: Marcus. Review in progress.
  - #10: Dashboard layout (Nina). Reviewer: James. Changes requested -- Nina is revising.

In QA (1):
  - #11: Portfolio view (Carlos). Margaret rejected the first pass -- test coverage
    at 62%, she wants 80%. Rachel is adding integration tests.

Blocked (1):
  - #23: Real-time data refresh strategy. Daniel flagged a scope risk -- the client's
    data provider rate-limits to 2 req/sec, which won't support the 500ms refresh
    interval in the original plan. Options in the issue. Needs your decision.

Team: Marcus (lead), Priya, Liam, Grace, Emma | QA: Victor | PM: Hannah
```

**Level 3:** Everything in Level 2, plus full transcripts of recent interactions -- Marcus's code review comments on Priya's WebSocket implementation, Margaret's QA rejection rationale with specific test gaps listed, Daniel's scope risk analysis with the data provider's rate limit documentation quoted, the internal discussion between Marcus and Daniel about fallback strategies.

### /jware-meeting -- Request a Meeting

**Invoked from:** The user's project directory
**Input:** Optional attendee requests, optional topic
**Purpose:** Conduct a live meeting with JWare employees

**Automatic attendees:** Daniel Kwon (SA) and the assigned PM are always present.

**User-requested attendees:**
```
/jware-meeting                          --> Daniel + PM
/jware-meeting with Marcus              --> Daniel + PM + Marcus Chen
/jware-meeting with Marcus and Margaret --> Daniel + PM + Marcus + Margaret
```

**JWare-suggested attendees:** Based on the topic, the PM may suggest pulling in additional people:
- Technical architecture question --> relevant dev lead
- QA concerns --> Margaret Chen (QA Lead)
- Security question --> Frank Morrison (Security Lead)
- Design question --> Olivia Hart (Design Lead)
- Timeline/resource question --> Ben Hartley (TPM)

**Meeting flow:**
1. PM opens the meeting, states the agenda
2. Each attendee contributes from their personality's perspective
3. Disagreements play out according to interpersonal dynamics
4. Meeting concludes with action items
5. Transcript saved to `.jware/meetings/{timestamp}-{topic}.md`
6. Action items become events in the queue or updates to issuetracker issues
7. Relevant conversation notes are appended to issuetracker issues

**Meeting output respects visibility level.** Even in a live meeting, level 1 shows only outcomes, level 2 shows key exchanges, level 3 shows full dialogue.

### /jware-dashboard -- Company-Wide Monitoring

**Invoked from:** The `JwareSolutions/` directory ONLY
**Input:** Optional visibility level (defaults to 2)
**Purpose:** Read-only view across ALL active JWare projects

**What it reads:**
1. `JwareSolutions/.jware/registry.json` for the list of active projects
2. Each project's `.jware/state.json` for status and team assignments
3. Each project's `.jware/issues/` for task counts and blockers

**Output:**
```
=== JWare Solutions Dashboard ===

Active Projects: 3
Total Team Utilization: 68%

PROJECT: Trader-X
  Path:     /Users/justinmalone/projects/trader-x
  Status:   Active | Phase: Development
  Team:     Marcus (lead), Priya, Liam, Grace, Emma | QA: Victor | PM: Hannah
  Progress: 8/14 complete | 2 in review | 1 in QA | 1 blocked
  Blocker:  Issue #23 (decision-needed)

PROJECT: HealthPortal
  Path:     /Users/justinmalone/projects/health-portal
  Status:   Active | Phase: Testing
  Team:     Sarah (lead), Derek, Carlos, Nina | QA: Rachel | PM: Jordan
  Progress: 11/11 complete | 0 in review | 3 in QA | 0 blocked
  Note:     Final QA pass. Margaret reviewing coverage report.

PROJECT: InternalTooling
  Path:     /Users/justinmalone/projects/internal-tools
  Status:   Active | Phase: Scoping
  Team:     Tomas (lead), Aisha, Sam | QA: Rachel (split) | PM: Hannah
  Progress: 0/0 (scoping in progress)
  Note:     Daniel completing technical discovery. Architecture proposal pending.

TEAM UTILIZATION:
  Marcus Chen:     Trader-X (80%)
  Sarah Kim:       HealthPortal (100%)
  Tomas Rivera:    InternalTooling (40%)
  Unallocated:     Alex Nguyen, Tyler Brooks, James O'Brien, Ryan Foster
```

At level 3, the dashboard includes recent event logs, meeting summaries, and internal discussion highlights from each project.

---

## 4. State Management

### Per-Project State (.jware/)

Every project that JWare is working on has a `.jware/` directory in the project root:

```
.jware/
  state.json                  # Project config, team assignments, visibility, phase
  events.json                 # Event queue -- ordered list of pending events
  processed-events.json       # Archive of processed events (audit trail)
  decisions/
    {id}-{slug}.json          # Decision records with full rationale
  meetings/
    {timestamp}-{topic}.md    # Meeting transcripts at configured visibility level
  reviews/
    {branch}-{reviewer}.md    # Code review records
  registry-entry.json         # This project's registration info
```

### state.json Schema

```json
{
  "projectName": "string",
  "projectPath": "string -- absolute path to the project root",
  "status": "intake | active | paused | review | completed",
  "visibility": 1,
  "phase": "intake | scoping | development | testing | review | delivery",
  "teams": [
    {
      "lead": "string -- personality name (e.g., 'Marcus Chen')",
      "members": ["string -- personality names"],
      "qa": "string -- assigned QA engineer name",
      "workstream": "string -- what this team is responsible for (e.g., 'Backend API')"
    }
  ],
  "pm": "string -- assigned PM name (Hannah Reeves or Jordan Pace)",
  "sa": "Daniel Kwon",
  "startDate": "ISO 8601",
  "greenfield": true,
  "techStack": ["string -- e.g., 'TypeScript', 'React', 'PostgreSQL'"],
  "specialDivisions": ["trading"],
  "gitStrategy": "single-branch | feature-branches | workstream-branches",
  "createdAt": "ISO 8601",
  "updatedAt": "ISO 8601"
}
```

**Field notes:**
- `status` tracks the project lifecycle. `paused` means the customer has stopped responding or explicitly paused. `review` means all dev/QA is done and Daniel is conducting final review.
- `visibility` is set during intake and can be changed by the customer at any time.
- `phase` tracks where the project is in the development lifecycle. Phases proceed in order but can regress (e.g., testing back to development if QA finds critical bugs).
- `teams` is an array because large projects may have multiple teams working on different workstreams.
- `specialDivisions` flags which specialty divisions are involved (currently only `trading`).
- `gitStrategy` is decided by the dev lead during scoping.

### events.json Schema

```json
{
  "events": [
    {
      "id": "string -- UUID",
      "type": "string -- event type (see event catalog below)",
      "payload": {},
      "createdAt": "ISO 8601",
      "createdBy": "string -- personality name or 'system' or 'customer'",
      "status": "pending | processing | processed | failed",
      "processedAt": "ISO 8601 | null"
    }
  ]
}
```

**Event Catalog (core types):**

| Event Type | Trigger | Payload | Engine Response |
|------------|---------|---------|-----------------|
| `project:intake` | `/jware` invoked | Plan document, project metadata | Start intake meeting, create scoping issues |
| `scoping:complete` | Intake meeting done, no pending questions | Team assignments, issue IDs | Transition to development phase |
| `scoping:questions-pending` | Intake found unresolved questions | Issue IDs with `decision-needed` | Wait for customer verdicts |
| `decision:approved` | Customer approves an issue | Issue ID, verdict | Act on the decision (proceed, accept scope, etc.) |
| `decision:rejected` | Customer rejects an issue | Issue ID, verdict, notes | Route to Daniel + PM to rethink and propose alternatives |
| `decision:deferred` | Customer defers an issue | Issue ID | Deprioritize; move to other work; resurface later |
| `task:ready` | Task unblocked, all dependencies met | Issue ID, assigned developer | Dispatch development agent |
| `dev:started` | Agent begins coding | Issue ID, developer, branch | Update issue status to `in_progress` |
| `dev:complete` | Agent finishes coding | Issue ID, developer, branch, commit SHA | Trigger code review assignment |
| `review:assigned` | Dev lead assigns reviewer | Issue ID, reviewer, branch | Dispatch reviewer agent |
| `review:approved` | Reviewer approves | Issue ID, reviewer | Trigger QA dispatch |
| `review:changes-requested` | Reviewer requests changes | Issue ID, reviewer, comments | Re-dispatch original developer |
| `qa:started` | QA agent begins testing | Issue ID, QA engineer | Update issue status |
| `qa:passed` | QA approves | Issue ID, QA engineer, coverage | Mark task complete |
| `qa:failed` | QA finds issues | Issue ID, QA engineer, failures | Create bug issues, re-dispatch developer |
| `bug:found` | Bug discovered during development | Description, severity, found-by | Create issue in issuetracker |
| `debt:identified` | Tech debt discovered | Description, impact, found-by | Create issue labeled `tech-debt` |
| `scope:risk` | Daniel identifies scope risk | Description, impact, options | Create issue labeled `scope-risk`, possibly `decision-needed` |
| `meeting:requested` | Customer or engine requests meeting | Topic, suggested attendees | Schedule and simulate meeting |
| `escalation:triggered` | Conflict cannot be resolved at current level | Participants, issue, level | Route to next level in escalation chain |
| `phase:transition` | Project moves to next phase | From phase, to phase | Update state, notify PM |

### processed-events.json Schema

Identical to `events.json` but only contains events with `status: "processed"` or `status: "failed"`. This is the audit trail. Events are appended, never modified once archived.

### Decision Records (.jware/decisions/)

```json
{
  "id": "string -- matches issuetracker issue ID",
  "slug": "string -- URL-safe summary (e.g., 'realtime-data-refresh-strategy')",
  "title": "string",
  "decidedBy": "string -- personality name or 'customer'",
  "decidedAt": "ISO 8601",
  "options": [
    {
      "label": "string -- e.g., 'Option A: Polling'",
      "description": "string",
      "advocatedBy": ["string -- personality names"],
      "pros": ["string"],
      "cons": ["string"]
    }
  ],
  "outcome": "string -- which option was chosen",
  "rationale": "string -- why this option was chosen",
  "escalated": false,
  "escalationPath": ["string -- e.g., 'Marcus Chen -> Raj Patel -> Customer'"]
}
```

### Meeting Transcripts (.jware/meetings/)

Filename format: `{YYYY-MM-DDTHH-MM-SS}-{topic-slug}.md`

Content format varies by visibility level:

**Level 1:**
```markdown
# Meeting: API Architecture Decision
**Date:** 2026-03-24T14:30:00Z
**Attendees:** Daniel Kwon, Hannah Reeves, Marcus Chen
**Outcome:** Decided on REST over GraphQL for the initial API layer. GraphQL may be
revisited for v2 if query complexity warrants it.
**Action Items:**
- Marcus to begin API scaffolding (Issue #4)
- Daniel to update scope document with REST assumption
```

**Level 2:**
```markdown
# Meeting: API Architecture Decision
**Date:** 2026-03-24T14:30:00Z
**Attendees:** Daniel Kwon, Hannah Reeves, Marcus Chen

## Discussion
Marcus advocated for GraphQL based on the query flexibility it would give the
frontend team. Daniel pushed back -- the client's existing services are all REST,
and introducing GraphQL would add a translation layer with no clear benefit for v1.
Marcus agreed that for the initial scope, REST is simpler, but asked Daniel to scope
a GraphQL migration path for v2. Daniel agreed and noted it in his assumptions register.

Hannah confirmed the timeline impact is neutral for v1 either way.

## Decision
REST for v1. GraphQL evaluation deferred to v2 scoping.

## Action Items
- Marcus to begin API scaffolding (Issue #4)
- Daniel to update scope document with REST assumption and v2 GraphQL note
```

**Level 3:** Full dialogue with personality-accurate language, tone, and interpersonal dynamics. Marcus's precise technical reasoning. Daniel's calibrated pushback citing the client's existing stack. Hannah's timeline framing. The specific moment Marcus shifted his position and why.

### Code Review Records (.jware/reviews/)

Filename format: `{branch-name}-{reviewer-name-slug}.md`

```markdown
# Code Review: feature/websocket-layer
**Reviewer:** Marcus Chen
**Author:** Priya Sharma
**Branch:** feature/websocket-layer
**Date:** 2026-03-24

## Summary
Priya's WebSocket implementation is clean and fast. Connection pooling is well
thought out. Two issues to address before merge.

## Comments

### src/ws/connection-manager.ts:45-62
**[Change Requested]** The reconnection logic uses a fixed 1-second retry interval.
This will hammer the server on sustained outages. Switch to exponential backoff
with jitter -- start at 100ms, cap at 30s. I can point you to the pattern we
used in the auth service if you want a reference.

### src/ws/message-handler.ts:112
**[Suggestion]** Consider adding a message type discriminator here rather than
relying on payload shape detection. It's not broken, but it'll be fragile when
we add new message types. This is the kind of thing that costs 10 minutes now
and saves 2 hours later.

## Verdict: Changes Requested
```

### Central Registry (JwareSolutions/.jware/registry.json)

```json
{
  "activeProjects": [
    {
      "name": "string -- project name",
      "path": "string -- absolute path to project root",
      "status": "string -- mirrors state.json status",
      "phase": "string -- mirrors state.json phase",
      "teams": [
        {
          "lead": "string",
          "workstream": "string"
        }
      ],
      "pm": "string",
      "startDate": "ISO 8601"
    }
  ],
  "teamUtilization": {
    "marcus-chen": {
      "allocated": true,
      "project": "Trader-X",
      "role": "lead",
      "capacity": 0.8
    },
    "priya-sharma": {
      "allocated": true,
      "project": "Trader-X",
      "role": "developer",
      "capacity": 1.0
    },
    "alex-nguyen": {
      "allocated": false,
      "project": null,
      "role": null,
      "capacity": 0.0
    }
  },
  "updatedAt": "ISO 8601"
}
```

**Utilization notes:**
- `capacity` is a float from 0.0 to 1.0 representing how much of a person's time is allocated
- A person can be split across projects (e.g., Rachel Kim at 0.5 on two projects)
- Dev leads are typically at 0.6-0.8 because they also do lead duties (reviews, meetings, planning)
- The TPM (Ben Hartley) manages allocation and updates this when teams are assigned or released

### Write Safety

All state file writes use atomic operations to prevent corruption:

```
1. Write content to a temporary file in the same directory
2. fsync the temporary file
3. Rename (atomic move) the temporary file over the target
```

This guarantees that:
- A crash during write leaves the old file intact
- No reader ever sees a partially-written file
- Concurrent sessions reading the same file always get a complete, consistent state

---

## 5. Multi-Session Support

The system is designed for concurrent sessions operating on the same project.

### Session Types

| Session | Role | Reads | Writes |
|---------|------|-------|--------|
| Engine session | Running `/jware-auto` -- processing events, dispatching agents, doing development | `.jware/`, `.jware/issues/`, source code | `.jware/events.json`, `.jware/processed-events.json`, source code, git branches |
| User session | Reviewing issues, having meetings, making decisions | `.jware/issues/`, `.jware/state.json` | `.jware/issues/issues/*.json` (verdicts), meeting requests |
| Observer session | Running `/jware-status` or `/jware-dashboard` | `.jware/`, `.jware/issues/` | Nothing (read-only) |

### Why This Works

1. **All state is file-based.** There is no in-memory-only state that would be lost if a session crashes or that another session couldn't see.

2. **Atomic writes.** Every file mutation uses write-to-temp-then-rename. A reader never sees a half-written file.

3. **Sessions mostly touch different files.** The engine writes code and events. The user writes verdicts and meeting requests. The observer reads only. The overlap surface is small.

4. **Event queue is append-only with processing markers.** New events are appended to `events.json`. Processing marks them as `processing` and then moves them to `processed-events.json`. A crash during processing leaves the event as `pending` and it will be retried on the next `/jware-auto`.

5. **Issuetracker uses atomic writes.** The issuetracker skill specifies atomic write semantics for all operations.

### Concurrency Limitations

This is not a database. There are known limitations:

| Scenario | Risk | Mitigation |
|----------|------|------------|
| Two engine sessions on the same project | Event could be processed twice | Only run one engine session per project at a time |
| User edits issue while engine is updating it | Last write wins | Acceptable -- user verdicts and engine updates touch different fields |
| Dashboard reads while engine writes | Dashboard may see slightly stale data | Acceptable -- dashboard is advisory |

**Rule:** One `/jware-auto` session per project at a time. Multiple observer and user sessions are safe.

---

## 6. Issuetracker Integration

The `.jware/issues/` is the shared nervous system between JWare and the customer. It is the project board, the communication channel, and the decision interface.

### What JWare Creates Issues For

| Category | When | Labels | Decision Needed? |
|----------|------|--------|-------------------|
| Scoped work items | During intake/scoping | Team name, workstream | No (unless scope is ambiguous) |
| Bugs found during QA | QA agent discovers a failure | `qa-failure`, team name | No |
| Bugs found during development | Developer discovers an issue | `bug`, severity | Sometimes (if blocking) |
| Technical debt | Developer or reviewer identifies debt | `tech-debt` | No (tracked, addressed as capacity allows) |
| Decisions needing customer input | Daniel or PM identifies a question | `decision-needed` | Yes |
| Blockers | Internal resolution failed or external dependency | `blocker` | Yes (if customer action needed) |
| Scope risks | Daniel identifies risk to timeline/budget | `scope-risk` | Sometimes |
| Architecture decisions | Significant technical decision made | `architecture` | No (informational) |

### Issue Metadata Conventions

JWare uses the issuetracker's standard schema with these conventions:

**`labels` field:**

| Label | Meaning |
|-------|---------|
| `decision-needed` | Customer must render a verdict before work proceeds |
| `blocker` | Something is preventing progress |
| `scope-risk` | Daniel has identified a risk to scope, timeline, or budget |
| `tech-debt` | Technical debt identified -- tracked, not urgent |
| `qa-failure` | QA test failure requiring developer fix |
| `bug` | Bug found during development |
| `architecture` | Architectural decision record |
| `{team-lead-name}` | Which team owns this (e.g., `marcus-chen`, `sarah-kim`) |
| `security` | Security-relevant issue (Frank Morrison involved) |
| `trading` | Trading Division involvement |

**`personas` field:** Populated with the JWare personality names who are actively involved with the issue. This is the source of truth for who is working on or concerned with an item.

**`reviews` field:** JWare personalities use the reviewer slots to log their technical opinions. The `notes` field contains personality-specific perspective:
- Marcus's notes are technically detailed with educational context
- Margaret's notes cite specific test coverage numbers and quality standards
- Daniel's notes frame scope and risk implications
- Frank's notes focus on security posture and compliance

**`userVote` field:** This is the customer's decision interface. When an issue is labeled `decision-needed`, the customer renders a verdict:

| Verdict | Engine Response |
|---------|----------------|
| `approve` | Engine acts on it. If it's a task, development proceeds. If it's a scope question, the scope is accepted. Generates `decision:approved` event. |
| `reject` | Engine routes back to Daniel + PM to rethink. They create alternatives, update the issue, and may re-request a decision. Generates `decision:rejected` event. |
| `defer` | Issue is deprioritized. Engine moves to other work. The deferred issue will be resurfaced later (during phase transitions or when it blocks something). Generates `decision:deferred` event. |

### Issuetracker Config for JWare Projects

When JWare initializes a project's `.jware/issues/`, it configures the reviewers to match the assigned team:

```json
{
  "name": "Trader-X",
  "nextIssueId": 1,
  "nextProjectId": 1,
  "reviewers": ["Daniel Kwon", "Hannah Reeves", "Marcus Chen", "Margaret Chen"]
}
```

Reviewers typically include: the SA (Daniel), the PM, the dev lead(s), and the QA lead. Additional reviewers (Security, Design) are added when relevant.

---

## 7. Greenfield vs Brownfield

The intake process differs significantly based on whether JWare is building from scratch or working with an existing codebase.

### Greenfield Projects

| Phase | What Happens |
|-------|-------------|
| **Intake** | Daniel proposes architecture from scratch. Technology choices are discussed with the customer. The dev lead has significant latitude on tech stack decisions within the customer's constraints. |
| **Design** | Olivia Hart (Design Lead) is pulled in early if the project has a user-facing component. Design decisions happen before development begins. Kai (UX) or Maya (Graphic Design) may be involved depending on scope. |
| **Scaffolding** | Full project scaffolding and setup is included in scope. This means repository structure, build configuration, CI/CD pipeline (Nathan Cross, DevOps Lead), linting/formatting configuration, and initial test infrastructure. |
| **Architecture** | Daniel writes a full architecture document as part of scoping. The dev lead reviews and proposes modifications. Disagreements are resolved before development starts. |
| **Estimation** | Daniel's estimates for greenfield are typically more precise because there are fewer unknowns in the existing codebase. Contingency is allocated for design iteration rather than legacy discovery. |

### Brownfield Projects

| Phase | What Happens |
|-------|-------------|
| **Intake** | Daniel performs a comprehensive codebase analysis: tech stack, architectural patterns, dependency health, test coverage, code style conventions, existing technical debt. This analysis is documented and shared with the dev lead. |
| **Existing Patterns** | JWare respects existing codebase patterns unless the plan explicitly calls for changing them. A React codebase that uses hooks and context gets hooks and context. A Python codebase that uses dataclasses gets dataclasses. Convention divergence requires customer approval. |
| **Security Review** | Frank Morrison (Security Lead) conducts a mandatory security assessment during scoping. This covers: dependency vulnerabilities, authentication/authorization patterns, data handling practices, and exposed attack surface. Findings become issues labeled `security`. |
| **History** | If an `.jware/issues/` already exists, JWare reads it for context. Past decisions, known issues, and deferred work are reviewed during scoping. Zoe Adams (Security Analyst) may be pulled in for deeper analysis. |
| **Estimation** | Daniel's estimates include contingency for unknown complexity -- code that looks simple but hides edge cases, undocumented dependencies, and legacy patterns that resist modification. Brownfield estimates are typically 15-25% wider than greenfield equivalents. |
| **Testing** | Margaret Chen (QA Lead) assesses existing test coverage during scoping. If coverage is below her threshold (typically 70%), improving coverage may be scoped as a prerequisite before new feature work begins. |

### Detection

The engine determines greenfield vs brownfield automatically:

| Signal | Greenfield | Brownfield |
|--------|------------|------------|
| Source files in repo | None or only scaffolding | Existing application code |
| Git history | 0-5 commits (initial setup only) | Substantial history |
| Package/dependency files | Empty or minimal | Populated |
| `.jware/issues/` history | None | Existing issues |
| Explicit customer declaration | "This is a new project" | "This is an existing codebase" |

The `greenfield` field in `state.json` records the determination.

---

## 8. Personality Loading

When a Claude agent is dispatched to act as a JWare employee, the agent is configured to behave as that person. This is not cosmetic -- it affects code style, review thoroughness, communication patterns, risk tolerance, and interpersonal dynamics.

### Loading Process

1. **Read the personality file.** The full profile is loaded from `JwareSolutions/personalities/{department}/{filename}.md`. This includes: overview, background, personality profile (MBTI type, communication style, work style, stress behavior, motivators, demotivators), core competencies, Amazon LP profile, strengths and blind spots, interpersonal dynamics, and quirks.

2. **Inject as system context.** The personality profile is loaded into the agent's system prompt alongside the task instructions.

3. **Provide project context.** The agent receives:
   - Access to the project codebase
   - The `.jware/issues/` state
   - The `.jware/` state relevant to their role
   - Their team's recent work (commits, reviews, meeting notes)
   - The specific task or issue they are working on

4. **Instruct behavioral adherence.** The agent is instructed to behave according to its personality across all dimensions:
   - MBTI type influences decision-making patterns
   - Communication style affects code comments, review tone, and meeting contributions
   - Work style affects code structure, thoroughness, and speed tradeoffs
   - Competencies determine what the agent does well and where it hedges
   - LP profile shapes how the agent handles ambiguity, risk, and conflict
   - Interpersonal dynamics affect how the agent responds to specific colleagues

### Personality Expression by Activity

| Activity | How Personality Manifests |
|----------|--------------------------|
| **Writing code** | Code style, variable naming, comment density, abstraction preferences, testing approach. Priya writes fast and opinionated code with minimal comments. Grace writes exhaustively documented code. Liam writes clever, sometimes too-clever code that Marcus reviews carefully. |
| **Code review** | Review depth, tone, focus areas. Marcus's reviews are detailed and educational -- he explains the "why" behind suggestions. Priya's reviews are blunt and focus on performance. Derek's reviews catch accessibility gaps others miss. |
| **Meeting participation** | Speaking style, what they advocate for, how they disagree. Sarah frames technical decisions in terms of user impact. Tomas focuses on operational reliability. Daniel speaks in specifics and calibrated risk language. |
| **Bug reports** | Detail level, tone. Margaret's QA reports are thorough with exact reproduction steps. Victor's reports include broader test coverage analysis. Rachel's reports focus on edge cases. |
| **Escalation** | How they handle conflict. Marcus mediates with patience. Tomas is direct to the point of bluntness. Daniel cites documentation. |

### Personality File Locations

All personality files are stored under:
```
$JWARE_HOME/personalities/
```

See [Section 9](#9-company-roster) for the complete file listing.

---

## 9. Company Roster

All 48 JWare Solutions employees, organized by department. Each entry includes name, title, reporting line, and personality file path.

### C-Suite (3)

| Name | Title | Reports To | File |
|------|-------|------------|------|
| Elena Vasquez | Chief Executive Officer | Board of Directors | `c-suite/ceo-elena-vasquez.md` |
| Raj Patel | Chief Technology Officer | CEO | `c-suite/cto-raj-patel.md` |
| Diana Okafor | Chief Operating Officer | CEO | `c-suite/coo-diana-okafor.md` |

**System role:** Elena sets company direction and handles escalations that reach the top. Raj is the ultimate technical authority -- all engineering escalations terminate with him. Diana manages operations, finance, and HR through her reports.

### Engineering (16)

#### Dev Leads (3)

| Name | Title | Reports To | Specialty | Direct Reports | File |
|------|-------|------------|-----------|----------------|------|
| Marcus Chen | Development Lead | CTO | Backend, API design, systems | Priya Sharma, Liam Kowalski, Grace Tanaka, Ryan Foster, Emma Liu | `engineering/dev-lead-marcus-chen.md` |
| Sarah Kim | Development Lead | CTO | Frontend, UX-engineering, full-stack | Derek Washington, James O'Brien, Carlos Mendez, Nina Petrov, Tyler Brooks | `engineering/dev-lead-sarah-kim.md` |
| Tomas Rivera | Development Lead | CTO | Infrastructure, DevOps-adjacent, systems reliability | Aisha Mohammed, Sam O'Connell, Alex Nguyen | `engineering/dev-lead-tomas-rivera.md` |

#### Senior Developers (5)

| Name | Title | Reports To | Strengths | File |
|------|-------|------------|-----------|------|
| Priya Sharma | Senior Developer | Marcus Chen | Fast, opinionated, backend performance | `engineering/senior-dev-priya-sharma.md` |
| Liam Kowalski | Senior Developer | Marcus Chen | Backend, database systems, clever solutions | `engineering/senior-dev-liam-kowalski.md` |
| Aisha Mohammed | Senior Developer | Tomas Rivera | Database architecture, infrastructure | `engineering/senior-dev-aisha-mohammed.md` |
| Derek Washington | Senior Developer | Sarah Kim | Frontend, accessibility, financial tech | `engineering/senior-dev-derek-washington.md` |
| James O'Brien | Senior Developer | Sarah Kim | Frontend, design-to-code, self-taught depth | `engineering/senior-dev-james-obrien.md` |

#### Mid-Level Developers (5)

| Name | Title | Reports To | File |
|------|-------|------------|------|
| Grace Tanaka | Mid-Level Developer | Marcus Chen | `engineering/mid-dev-grace-tanaka.md` |
| Ryan Foster | Mid-Level Developer | Marcus Chen | `engineering/mid-dev-ryan-foster.md` |
| Carlos Mendez | Mid-Level Developer | Sarah Kim | `engineering/mid-dev-carlos-mendez.md` |
| Nina Petrov | Mid-Level Developer | Sarah Kim | `engineering/mid-dev-nina-petrov.md` |
| Sam O'Connell | Mid-Level Developer | Tomas Rivera | `engineering/mid-dev-sam-oconnell.md` |

#### Junior Developers (3)

| Name | Title | Reports To | File |
|------|-------|------------|------|
| Emma Liu | Junior Developer | Marcus Chen | `engineering/junior-dev-emma-liu.md` |
| Tyler Brooks | Junior Developer | Sarah Kim | `engineering/junior-dev-tyler-brooks.md` |
| Alex Nguyen | Junior Developer | Tomas Rivera | `engineering/junior-dev-alex-nguyen.md` |

### QA (3)

| Name | Title | Reports To | Embedded With | File |
|------|-------|------------|---------------|------|
| Margaret Chen | QA Lead | CTO | All teams (oversight) | `qa/qa-lead-margaret-chen.md` |
| Victor Santos | QA Engineer | Margaret Chen | Marcus Chen's team | `qa/qa-engineer-victor-santos.md` |
| Rachel Kim | QA Engineer | Margaret Chen | Sarah Kim's & Tomas Rivera's teams (split) | `qa/qa-engineer-rachel-kim.md` |

**System role:** Margaret sets quality standards and coverage thresholds. Victor and Rachel are embedded with development teams and run QA on completed work. Margaret reviews their findings and has final authority on quality gates.

### DevOps (2)

| Name | Title | Reports To | File |
|------|-------|------------|------|
| Nathan Cross | DevOps Lead | CTO | `devops/devops-lead-nathan-cross.md` |
| Jasmine Wu | DevOps Engineer | Nathan Cross | `devops/devops-engineer-jasmine-wu.md` |

**System role:** Nathan handles CI/CD pipeline setup, deployment strategy, and infrastructure decisions. Jasmine implements and maintains the infrastructure. Both are pulled in during scoping for greenfield projects and for any project with deployment requirements.

### Security (2)

| Name | Title | Reports To | File |
|------|-------|------------|------|
| Frank Morrison | Security Lead | CTO | `security/security-lead-frank-morrison.md` |
| Zoe Adams | Security Analyst | Frank Morrison | `security/security-analyst-zoe-adams.md` |

**System role:** Frank conducts mandatory security reviews on brownfield projects during scoping and optional reviews on greenfield projects. Zoe performs deeper analysis -- dependency auditing, vulnerability scanning, compliance checking. Security issues are labeled `security` in the issuetracker and Frank or Zoe are added to the `personas` field.

### Design (3)

| Name | Title | Reports To | File |
|------|-------|------------|------|
| Olivia Hart | Design Lead | CTO | `design/design-lead-olivia-hart.md` |
| Kai Oduya | UI/UX Designer | Olivia Hart | `design/ux-designer-kai-oduya.md` |
| Maya Russo | Graphic Designer | Olivia Hart | `design/graphic-designer-maya-russo.md` |

**System role:** Olivia is pulled in during scoping for any project with a user-facing component. She makes design system decisions and delegates UX work to Kai and visual work to Maya. Design decisions happen before development begins on greenfield projects and are integrated into the sprint for brownfield projects.

### Project Management (3)

| Name | Title | Reports To | File |
|------|-------|------------|------|
| Ben Hartley | Technical Program Manager | COO | `pm/tpm-ben-hartley.md` |
| Hannah Reeves | Project Manager | Ben Hartley | `pm/pm-hannah-reeves.md` |
| Jordan Pace | Project Manager | Ben Hartley | `pm/pm-jordan-pace.md` |

**System role:** Ben is the team allocator. He assigns teams based on project size, type, and current utilization. He does not interact directly with customers. Hannah and Jordan are the customer-facing PMs -- one is assigned per project. They manage communication, track progress, surface blockers, and run meetings. They are ALWAYS present in customer interactions alongside Daniel.

### Solutions Architecture (1)

| Name | Title | Reports To | File |
|------|-------|------------|------|
| Daniel Kwon | Solutions Architect | CTO | `solutions/solutions-architect-daniel-kwon.md` |

**System role:** Daniel is the single most important role in the JWare system. He is present at every intake, runs technical discovery, writes scope documents, identifies risks, and stays visible into early delivery. He is the technical conscience of every engagement. His assumptions register is the source of truth for what JWare committed to and what needs to be true for those commitments to hold.

### Sales & Business Development (2)

| Name | Title | Reports To | File |
|------|-------|------------|------|
| Patricia Walsh | Sales Director | CEO | `sales/sales-director-patricia-walsh.md` |
| Marcus Johnson | Business Development Rep | Patricia Walsh | `sales/bd-rep-marcus-johnson.md` |

**System role:** Patricia and Marcus are not directly involved in project execution. They handle pre-sales pipeline, client relationships, and renewal conversations. In the JWare simulation, they are available for meetings where commercial context matters (pricing discussions, scope negotiations with budget implications, renewal planning). They are not dispatched as coding or reviewing agents.

### Marketing & PR (2)

| Name | Title | Reports To | File |
|------|-------|------------|------|
| Claire Bennett | Marketing Manager | CEO | `marketing/marketing-manager-claire-bennett.md` |
| Ethan Cole | PR & Content Specialist | Claire Bennett | `marketing/pr-specialist-ethan-cole.md` |

**System role:** Claire and Ethan are support functions. They are available for meetings where project outcomes need to be communicated externally (release announcements, client-facing documentation, public-facing content). They are not part of the core development loop.

### Support (2)

| Name | Title | Reports To | File |
|------|-------|------------|------|
| Kevin Shaw | Support Lead | COO | `support/support-lead-kevin-shaw.md` |
| Lisa Tran | Support Technician | Kevin Shaw | `support/support-tech-lisa-tran.md` |

**System role:** Kevin and Lisa handle post-delivery support concerns. They are relevant when a project is in the delivery or maintenance phase, or when a customer reports issues with previously delivered work. Kevin has context on the customer's operational environment that can inform scoping decisions.

### Operations (3)

| Name | Title | Reports To | File |
|------|-------|------------|------|
| Helen Park | Controller | COO | `operations/controller-helen-park.md` |
| Sandra Mitchell | HR Manager | COO | `operations/hr-manager-sandra-mitchell.md` |
| Tony Martinez | Office Administrator | Sandra Mitchell | `operations/office-admin-tony-martinez.md` |

**System role:** Operations staff manage internal company functions. Helen handles financial tracking and margin analysis on projects (relevant in scope negotiations and project economics discussions). Sandra manages team health and interpersonal issues (relevant when personality conflicts affect project work). Tony handles logistics. These roles rarely surface in customer-facing interactions but exist in the organizational fabric.

### Trading Division (6)

The Trading Division is a specialized unit that activates for any project tagged as trading-related. These personalities are pulled in during team allocation when the project involves financial trading systems, quantitative analysis, DeFi/crypto, or market data infrastructure.

| Name | Title | Reports To | Specialty | File |
|------|-------|------------|-----------|------|
| TBD | Senior Managing Director | CEO | Division head, Wall Street veteran, P&L responsibility | `trading/smd-{name}.md` |
| TBD | Quantitative Analyst | SMD | Statistical modeling, backtesting, alpha research | `trading/quant-{name}.md` |
| TBD | Trading Systems Architect | SMD | Low-latency systems, market data, execution engines | `trading/systems-architect-{name}.md` |
| TBD | Crypto/DeFi Specialist | SMD | Blockchain, smart contracts, DEX integration, tokenomics | `trading/crypto-defi-{name}.md` |
| TBD | Risk & Compliance Analyst | SMD | Risk modeling, regulatory compliance, audit readiness | `trading/risk-compliance-{name}.md` |
| TBD | Domain Expert (Former Trader) | SMD | Market microstructure, trading workflows, user requirements | `trading/domain-expert-{name}.md` |

**System role:** The Trading Division operates as a consultancy-within-a-consultancy. When a project is tagged `trading` during intake, Ben Hartley pulls in relevant Trading Division members alongside the standard engineering team. The SMD has authority over trading-domain technical decisions. The Trading Systems Architect collaborates with the assigned dev lead on architecture. The Quant and Domain Expert validate that the system being built reflects real trading workflows and quantitative requirements. Risk & Compliance ensures regulatory and risk management concerns are addressed. The Crypto/DeFi Specialist is engaged for any blockchain or decentralized finance component.

**Trading Division activation criteria:**
- Project plan mentions trading, financial markets, or quantitative analysis
- Tech stack includes market data feeds, FIX protocol, or exchange connectivity
- Customer explicitly tags the project as trading-related
- Daniel Kwon identifies trading-domain complexity during discovery

---

## 10. Design Principles

These principles are not aspirational. They are constraints that the implementation must satisfy.

### File-Based Persistence

All state lives in files. No in-memory-only state. Sessions can crash and resume. A new session reads files and knows everything the previous session knew. This is the foundation everything else is built on.

**Implication:** Every piece of information that matters -- team assignments, event queues, decisions, meeting outcomes, review results -- must be written to a file before it is considered real. If it is not on disk, it did not happen.

### Atomic Writes

All file writes use the write-to-temp-then-rename pattern. This is non-negotiable.

```
write(content) -> temp file in same directory
fsync(temp file)
rename(temp file, target file)
```

**Implication:** No reader ever sees a partially written file. No crash ever corrupts state. The cost is slightly more complex write operations. The benefit is that the system is resilient to failures at any point.

### Issuetracker as Backbone

The `.jware/issues/` is the primary communication and decision interface between JWare and the customer. It is not a secondary artifact -- it is the shared nervous system.

**Implication:** Every significant interaction between JWare and the customer is recorded in the issuetracker. Decisions, blockers, scope risks, QA failures, architecture records -- they all live here. The customer can understand the state of their project by reading the issuetracker alone, without needing to understand JWare's internal `.jware/` state.

### Personalities Drive Behavior

Agents do not just write code. They write code AS their personality. This is not flavor text -- it affects technical decisions, review quality, communication patterns, and interpersonal dynamics.

**Implication:** When Marcus Chen reviews code, the review reflects his documented style: detailed, educational, with a focus on maintainability. When Priya Sharma writes code, it is fast and opinionated with clear performance consideration. When Daniel Kwon identifies a scope risk, his language is precise and calibrated in the way his profile describes. The personality is the agent's operating instructions, not decoration.

### Escalation Over Deadlock

When the company cannot resolve an issue internally, it escalates to the customer rather than stalling. Work does not stop while waiting for resolution -- the engine moves to other ready tasks and returns to the blocked item when the decision arrives.

**Implication:** The escalation chain is deterministic:
```
Developer <-> Developer (peer discussion)
  --> Dev Lead mediates
    --> CTO decides (for technical disputes)
    --> COO decides (for resource/process disputes)
      --> Customer decides (for scope/direction disputes)
```

Every level has a defined owner. No issue is ever "stuck" -- it is either being worked, being discussed, or waiting for a specific person's decision.

### Real Output

This writes real code, makes real commits, creates real branches, runs real tests, and produces real reviews. It is not a simulation of work. It is work done by simulated people.

**Implication:** The user's repository changes. Git history accumulates. Tests pass or fail. Code reviews have substantive technical content. The output is indistinguishable from work done by a real development team -- because it is real development work, guided by personality-driven agents with technical competence, opinions, and professional standards.

---

## Appendix A: Organizational Chart

```
Elena Vasquez (CEO)
├── Raj Patel (CTO)
│   ├── Marcus Chen (Dev Lead — Backend)
│   │   ├── Priya Sharma (Senior)
│   │   ├── Liam Kowalski (Senior)
│   │   ├── Grace Tanaka (Mid)
│   │   ├── Ryan Foster (Mid)
│   │   └── Emma Liu (Junior)
│   ├── Sarah Kim (Dev Lead — Frontend/Full-Stack)
│   │   ├── Derek Washington (Senior)
│   │   ├── James O'Brien (Senior)
│   │   ├── Carlos Mendez (Mid)
│   │   ├── Nina Petrov (Mid)
│   │   └── Tyler Brooks (Junior)
│   ├── Tomas Rivera (Dev Lead — Infrastructure)
│   │   ├── Aisha Mohammed (Senior)
│   │   ├── Sam O'Connell (Mid)
│   │   └── Alex Nguyen (Junior)
│   ├── Margaret Chen (QA Lead)
│   │   ├── Victor Santos (QA — embedded w/ Marcus's team)
│   │   └── Rachel Kim (QA — embedded w/ Sarah's & Tomas's teams)
│   ├── Nathan Cross (DevOps Lead)
│   │   └── Jasmine Wu (DevOps Engineer)
│   ├── Frank Morrison (Security Lead)
│   │   └── Zoe Adams (Security Analyst)
│   ├── Olivia Hart (Design Lead)
│   │   ├── Kai Oduya (UI/UX Designer)
│   │   └── Maya Russo (Graphic Designer)
│   └── Daniel Kwon (Solutions Architect)
├── Diana Okafor (COO)
│   ├── Ben Hartley (TPM)
│   │   ├── Hannah Reeves (PM)
│   │   └── Jordan Pace (PM)
│   ├── Kevin Shaw (Support Lead)
│   │   └── Lisa Tran (Support Technician)
│   ├── Sandra Mitchell (HR Manager)
│   │   └── Tony Martinez (Office Admin)
│   └── Helen Park (Controller)
├── Patricia Walsh (Sales Director)
│   └── Marcus Johnson (BD Rep)
└── Claire Bennett (Marketing Manager)
    └── Ethan Cole (PR Specialist)

Trading Division (reports to CEO):
├── TBD — Senior Managing Director
│   ├── TBD — Quantitative Analyst
│   ├── TBD — Trading Systems Architect
│   ├── TBD — Crypto/DeFi Specialist
│   ├── TBD — Risk & Compliance Analyst
│   └── TBD — Domain Expert (Former Trader)
```

### Appendix B: File Path Reference

All personality files are relative to:
```
$JWARE_HOME/personalities/
```

| Department | Files |
|------------|-------|
| C-Suite | `c-suite/ceo-elena-vasquez.md`, `c-suite/cto-raj-patel.md`, `c-suite/coo-diana-okafor.md` |
| Engineering — Leads | `engineering/dev-lead-marcus-chen.md`, `engineering/dev-lead-sarah-kim.md`, `engineering/dev-lead-tomas-rivera.md` |
| Engineering — Senior | `engineering/senior-dev-priya-sharma.md`, `engineering/senior-dev-liam-kowalski.md`, `engineering/senior-dev-aisha-mohammed.md`, `engineering/senior-dev-derek-washington.md`, `engineering/senior-dev-james-obrien.md` |
| Engineering — Mid | `engineering/mid-dev-grace-tanaka.md`, `engineering/mid-dev-ryan-foster.md`, `engineering/mid-dev-carlos-mendez.md`, `engineering/mid-dev-nina-petrov.md`, `engineering/mid-dev-sam-oconnell.md` |
| Engineering — Junior | `engineering/junior-dev-emma-liu.md`, `engineering/junior-dev-tyler-brooks.md`, `engineering/junior-dev-alex-nguyen.md` |
| QA | `qa/qa-lead-margaret-chen.md`, `qa/qa-engineer-victor-santos.md`, `qa/qa-engineer-rachel-kim.md` |
| DevOps | `devops/devops-lead-nathan-cross.md`, `devops/devops-engineer-jasmine-wu.md` |
| Security | `security/security-lead-frank-morrison.md`, `security/security-analyst-zoe-adams.md` |
| Design | `design/design-lead-olivia-hart.md`, `design/ux-designer-kai-oduya.md`, `design/graphic-designer-maya-russo.md` |
| PM | `pm/tpm-ben-hartley.md`, `pm/pm-hannah-reeves.md`, `pm/pm-jordan-pace.md` |
| Solutions | `solutions/solutions-architect-daniel-kwon.md` |
| Sales | `sales/sales-director-patricia-walsh.md`, `sales/bd-rep-marcus-johnson.md` |
| Marketing | `marketing/marketing-manager-claire-bennett.md`, `marketing/pr-specialist-ethan-cole.md` |
| Support | `support/support-lead-kevin-shaw.md`, `support/support-tech-lisa-tran.md` |
| Operations | `operations/controller-helen-park.md`, `operations/hr-manager-sandra-mitchell.md`, `operations/office-admin-tony-martinez.md` |
| Trading | `trading/smd-{name}.md`, `trading/quant-{name}.md`, `trading/systems-architect-{name}.md`, `trading/crypto-defi-{name}.md`, `trading/risk-compliance-{name}.md`, `trading/domain-expert-{name}.md` |
