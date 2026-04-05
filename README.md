# JWare Solutions

A 48-person event-driven virtual software company built on Claude Code. You bring a plan. JWare Solutions builds the software — end to end, with real code, real reviews, real QA, and real personality-driven decisions.

---

## What Is JWare Solutions

JWare Solutions is not a code generation tool wearing a company costume. It is a full software organization simulation: 48 people with distinct personalities, reporting chains, technical opinions, and interpersonal dynamics — each dispatched as a real Claude agent that writes real code in your real repositories.

When you submit a project:

- A Solutions Architect and Project Manager conduct a proper intake meeting with you
- Teams are scoped and allocated based on project type, size, and tech stack
- Developers write real code on real branches with personality-driven style and opinions
- Developers review each other's code — and they disagree, escalate, and resolve
- QA runs actual test suites and files real bug reports
- You receive outcomes, key decisions, or full internal process — depending on how much visibility you want
- Decisions that require your input surface cleanly through a structured issue interface

The company handles greenfield and brownfield projects. Multiple concurrent projects can run simultaneously with dedicated, separately allocated teams.

---

## Quick Start

### Setup

```bash
/plugin marketplace add https://github.com/jwaresolutions/JwareSolutionsForClaude
/plugin install jware-solutions
```

That's it. Skills, agents, hooks, and scripts are registered automatically. `JWARE_HOME` is set to the plugin install directory — no manual configuration needed.

### Start a Project

From any project directory:

```
/jware
```

That is the entire entry point. Daniel Kwon (Solutions Architect) and a Project Manager will conduct your intake meeting, scope the work, and take it from there.

### All Commands

| Command | What It Does |
|---------|-------------|
| `/jware` | Submit a new project for intake |
| `/jware-auto` | Run Jane (orchestration AI) — autonomous development cycles |
| `/jware-auto N cycles` | Run exactly N development cycles |
| `/jware-status [1\|2\|3]` | Check project progress at a given visibility level |
| `/jware-meeting [with Name]` | Request a meeting with your contacts |
| `/jware-dashboard [1\|2\|3]` | Monitor all active projects (run from the JwareSolutions directory) |

---

## When to Use JWare vs. Superpowers

JWare Solutions and oh-my-claudecode (Superpowers) both run on Claude Code, but they solve different problems. JWare does **not** depend on oh-my-claudecode — it runs standalone with just Claude Code. If you have Superpowers installed, they coexist without conflict.

| | Superpowers | JWare Solutions |
|---|------------|----------------|
| **Model** | You are the developer, AI is your tool | You are the customer, JWare is your development team |
| **Process** | Direct — you say what to do, AI does it | Structured — intake, scoping, review, QA, delivery |
| **Quality gates** | Optional (TDD skill, code review skill) | Mandatory — JARVIS, 4 completion gates, DevOps approval, two-phase QA |
| **Context** | Single agent or parallel agents, your context | 48 personalities with opinions, dynamics, and institutional memory |
| **Oversight** | You review the code yourself | Code reviews, QA, and verification happen inside the company before you see the output |
| **State** | Session-scoped (tasks, plans) | Persistent file-based state across sessions and projects |

### Use Superpowers when:
- You want direct control over what gets written
- The task is a quick fix, prototype, or single-feature change
- You're debugging and need to iterate fast
- You want to use specific skills (TDD, brainstorming, security review) a la carte

### Use JWare when:
- The project has enough scope that structured process adds value (10+ tasks, multiple concerns)
- You want quality gates enforced automatically, not manually
- You want autonomous execution — set it running and check in later
- The project benefits from multiple perspectives (backend, frontend, QA, security, DevOps reviewing the same work)
- You want persistent state that survives across sessions and tracks decisions, risks, and progress over time

They are complementary. Superpowers handles the execution mechanics. JWare adds organizational process, quality enforcement, and personality-driven judgment on top.

---

## Context Management

Long AI prompts get deprioritized — the AI picks what it likes and skips what it finds inconvenient. JWare is architecturally designed to prevent this.

### Modular Skill Architecture

Every skill is a thin router (~100-350 lines) that references shared engine modules instead of carrying duplicated content. No single file is large enough for the AI to start skipping instructions.

| Component | Purpose | Example |
|-----------|---------|---------|
| **Skills** (~100-350 lines) | Entry points that define the unique workflow for each command | `jware-auto/SKILL.md` — Jane's cycle loop |
| **Engine modules** (~50-120 lines) | Shared reference docs loaded on demand by multiple skills | `engine/roster.md` — 48-person name/path lookup |
| **Shell scripts** | Deterministic operations the AI cannot reinterpret | `jware-issue.sh` — issue CRUD with atomic writes |

Skills reference modules by path (`engine/meeting-protocol.md`) instead of embedding their content. The AI loads only what it needs for the current phase.

### Phase-Based Fresh Context

Jane (the orchestration AI) runs as a thin L0 coordinator. Each development phase (planning, execution, verification, closeout) is dispatched as a separate L1 agent with a **fresh context** containing only that phase's instructions. Phase agents save results to disk and return compact summaries. Jane's context never accumulates phase details.

```
Jane (L0) — thin, persistent, manages the cycle
  ├─ L1: Planning agent — fresh context, reads state, writes plan
  ├─ L1: Execution agent — fresh context, spawns teams, monitors
  ├─ L1: Verification agent — fresh context, runs gates
  └─ Jane does closeout herself (requires cross-phase judgment)
```

### Disk-Based State

All coordination state lives on disk, not in agent memory. Sessions can crash and resume with zero data loss. The phase state machine (`jane-phase.json`) tracks exactly where the system is, so recovery is always possible.

### Deterministic Shell Scripts

Operations that must produce consistent results regardless of AI interpretation are implemented as shell scripts, not AI instructions:

| Script | What It Does |
|--------|-------------|
| `jware-issue.sh` | All issue CRUD — atomic writes, cycle detection, ID allocation |
| `jware-file-lock.sh` | File locking between teams — acquire, release, check, force-release |
| `jware-task-counts.sh` | Compute task counts from issue files — consistent JSON output |
| `jware-state-check.sh` | Validate project prerequisites — structured pass/fail |
| `jware-deploy-check.sh` | Detect and run CI/CD pipelines — GitHub Actions, Make, Docker, npm |
| `jware-tree-update.sh` | Render the live orchestration tree view — consistent formatting |

The AI calls these scripts via bash. It cannot "creatively reinterpret" the locking protocol or issue schema.

### Skill Size Monitoring

A session-start hook scans all skill and engine files on every conversation start. Files exceeding 200 lines trigger a warning. Files exceeding 400 lines trigger a critical alert. This catches growth before it becomes a deprioritization problem.

### Context Checkpoint

If Jane approaches 80% context capacity during a long orchestration session, she writes a checkpoint file with her full state, notifies the customer, and exits cleanly. The next `/jware-auto` invocation detects the checkpoint and resumes from exactly where she left off.

---

## Software Development Quality Control

JWare enforces quality at every stage — not as suggestions, but as hard gates that block progress until they pass.

### Completion Gates (4 mandatory checks per task)

Before ANY task is considered complete, it must pass all four gates. These are not optional.

| Gate | What It Checks | Failure Mode |
|------|---------------|-------------|
| **Deployment Verification** | Code actually deploys — CI/CD pipeline passes, not just tests | Task returns to team with deployment error |
| **Dead Code Cleanup** | Old implementation is removed, not just bypassed — no orphaned imports, stale routes, dead config | Task returns to developer |
| **Spec Compliance** | Implementation matches the original issue spec literally, not "it generally works" | Task returns if any acceptance criterion is unmet |
| **No Placeholders** | No buttons that do nothing, no "coming soon" pages, no hardcoded mock data, no empty function bodies | Critical defect — task cannot pass |

### Test-Driven Development

All developer agents follow a TDD workflow: write failing tests first (committed as `test: add failing tests`), then implement to make them pass (committed as `feat/fix: {description}`), then optionally refactor as a separate step. This is enforced at the agent level, not suggested.

### JARVIS Verification Gate

JARVIS is JWare's automated verification system that runs between task completion and code review. No code reaches a reviewer without passing JARVIS first. Checks run in fail-fast order:

1. **Dependencies** — install and resolve
2. **Build** — compilation, type checking
3. **Lint** — code style rules
4. **Tests** — full test suite execution
5. **Coverage** — measured on changed files only, threshold set per project by Margaret Chen

JARVIS detects stale mocks — when tests reference outdated interfaces through signature mismatches, it flags them specifically rather than letting them produce confusing runtime failures.

**Three-failure escalation:** If a developer fails JARVIS three consecutive times on the same task, it escalates to the dev lead as an internal conflict rather than sending the developer in circles.

**Cross-team integration:** After all teams complete in a cycle, JARVIS runs again across all completed work to verify that changes from different teams integrate correctly. Max 2 passes at this level — if it still fails, the issues are recorded and surfaced.

### DevOps Approval Gate

Every development cycle with new tasks requires DevOps sign-off before execution begins. Nathan Cross (DevOps Lead) reviews the plan for:

- Deployment path and rollback strategy
- Monitoring and observability
- Operational soundness
- Infrastructure implications

If Nathan flags concerns, the PM adjusts the plan before any code is written. Pre-existing tasks are grandfathered.

### Code Review

Code reviews are conducted by personality-driven reviewers who bring their documented expertise and opinions. Reviews are not rubber stamps:

- Marcus Chen writes detailed, educational reviews that explain the "why"
- Priya Sharma's reviews are fast and direct — she catches performance issues others miss
- Margaret Chen rejects at 62% coverage when her threshold is 80%, every time

If changes are requested, the original developer is re-dispatched with the reviewer's feedback. Approved code proceeds to QA.

### Two-Phase QA Testing

QA runs in two phases for projects with user interfaces:

**Phase 1 — Professional QA:** Margaret Chen's team (Victor Santos, Rachel Kim) tests interactively using browser automation tools against acceptance criteria and key user flows. They navigate the actual running application — clicking buttons, filling forms, verifying behavior. If Phase 1 fails, the task returns to the developer and Phase 2 is skipped.

**Phase 2 — User Panel:** 2-3 panelists from a diverse pool test the feature based on plain-language tasks, not developer acceptance criteria. A school administrator, a small business owner, and a delivery driver try to use the software the way real people would. If ANY panelist gets stuck or finds issues, the task fails QA. Margaret selects panelists based on task type — form-heavy tasks get different panelists than mobile-responsive tasks.

Before QA starts, the system probes each required tool (e.g., browser automation). If a tool is unavailable, it creates a `decision-needed` issue and stops — it never silently falls back to code-only testing.

### File Locking

When multiple teams work in the same repository, file locks prevent merge conflicts. Before a developer touches a file, the system checks if another team holds a lock on it. Locks are held until JARVIS verification passes (not just until the developer finishes). Stale locks are detected and force-released with logging.

### Risk Register

During intake, Daniel Kwon populates a risk register with specific, evidence-based technical risks — not vague categories but named constraints with likelihood, impact, mitigation strategies, and assigned owners. Risks are cross-referenced to the issues they affect.

### Dependency Cycle Detection

Issue dependencies (`blockedBy`) are validated with DFS cycle detection before any write. If adding a dependency would create a circular block (A waits on B waits on A), the operation is rejected with an explanation of the cycle path.

### Retro and Continuous Improvement

Jane runs a retrospective every development cycle. Team leads and the PM participate in character, producing:

- What went well (practices to spread across teams)
- What went wrong (patterns to fix)
- Action items (specific, assignable changes)

Jane processes action items herself — allowing, blocking, or modifying based on her cross-project perspective. She can auto-apply process changes, prompt tweaks, and threshold adjustments. Changes requiring customer approval (team structure, scope, architecture) surface as decision-needed issues.

### Personality-Driven Quality

Quality is not just process — it is culture. Every JWare employee has a documented personality that shapes how they approach quality:

- Margaret Chen will not accept "the unhappy path is unlikely" as a reason to skip testing
- Frank Morrison sees security risks others miss and frames them as non-negotiable
- Daniel Kwon pushes back on scope with specific technical evidence — he has told clients their requirements were infeasible within the first twenty minutes
- Tomas Rivera says twelve words about infrastructure when others say sixty, and his twelve are the right ones

These are not decorative. They drive real behavioral differences in code output, review quality, and decision-making.

---

## How a Project Moves Through JWare

1. **You bring a plan.** Run `/jware` from your project directory. Anything from a rough idea to a detailed spec.

2. **Intake meeting.** Daniel Kwon (Solutions Architect) and either Hannah Reeves or Jordan Pace (Project Manager) meet with you to clarify scope, constraints, and requirements.

3. **Scoping and issue creation.** Daniel produces architecture proposals and estimates. The team breaks the project into tracked issues with dependencies, priorities, and acceptance criteria.

4. **Team allocation.** Ben Hartley (TPM) assigns teams based on project size, tech stack, domain, and current company utilization. Juniors always get senior coverage. Leads are never split across more than two projects.

5. **Development.** Jane orchestrates cycles: plan → execute → verify → closeout. Teams are dispatched in parallel. Developers write real code. Reviewers review real diffs. QA tests real builds.

6. **Delivery.** Completed work lands on the agreed branch. Your contacts brief you on the outcome. Open items surface clearly.

---

## Your Point of Contact

You interact with exactly two people:

| Role | Person | Responsibility |
|------|--------|---------------|
| Solutions Architect | Daniel Kwon | Technical truth — architecture, tradeoffs, implementation decisions |
| Project Manager | Hannah Reeves or Jordan Pace | Relationship and process — scope, timeline, blockers, communication |

No other JWare employee initiates direct contact with you unless you specifically request them in a meeting. All internal noise stays inside the company unless your visibility level is set to show it.

---

## Making Decisions

JWare runs on your decisions, not in spite of them.

When JWare needs your input:

1. A `decision-needed` issue is created with options, developer notes, and JWare's recommendation
2. You discuss it with Daniel and your PM via `/jware-meeting`
3. You render a verdict: `approve`, `reject`, or `defer`
4. The company acts on your verdict in the next cycle

---

## Visibility Levels

You control how much of the company's internal process you see.

| Level | Name | What You See |
|-------|------|-------------|
| 1 | Outcomes | Task counts, completion percentages, blockers, decisions needed. No internal dynamics. |
| 2 | Key Decisions | Who debated what, why they chose approach X over Y, how disagreements were resolved. |
| 3 | Full Process | Meeting transcripts, code review dialogue, personality-driven debates, escalation chains. |

Change at any time with `/jware-status [1|2|3]`.

---

## Multi-Session Support

All state is file-based, so parallel sessions see each other's changes in real time.

| Session | What You Do |
|---------|------------|
| Session 1 | `/jware-auto` — the company works |
| Session 2 | Review issues, have meetings, make decisions |
| Session 3 | `/jware-status 3` — watch the full internal process |

A decision you make in Session 2 will be picked up by Session 1 on its next event cycle.

---

## Project Structure

```
JwareSolutions/
├── skills/              Entry points (/jware, /jware-auto, etc.)
├── engine/              Shared modules (roster, protocols, schemas)
├── scripts/             Shell scripts and hooks (registered via plugin)
│   ├── jware-issue.sh       Issue CRUD with atomic writes + cycle detection
│   ├── jware-file-lock.sh   Cross-team file locking
│   ├── jware-task-counts.sh Task count computation
│   ├── jware-state-check.sh Prerequisite validation
│   ├── jware-deploy-check.sh CI/CD pipeline detection and execution
│   ├── jware-spawn-team.sh  Tmux team agent launcher
│   └── jware-*-hook.mjs     Session, channel, tree, and meeting hooks
├── hooks/               Plugin hook registration (hooks.json)
├── agents/              14 agent definitions for team/role dispatch
├── personalities/       48 personality profiles by department
├── templates/           State file templates for new projects
├── docs/architecture/   System design specs
├── settings.json        Default env vars (JWARE_HOME)
└── .claude-plugin/      Plugin manifest
```

Each project you submit gets its own `.jware/` directory in your repository — not here. JWare's company state lives in `$JWARE_HOME/.jware/registry.json`.

---

## Orchestration and Architecture

### Cascading Agent Hierarchy

JWare uses a three-level agent architecture. This isn't arbitrary nesting — each level exists because of a specific constraint in how Claude Code manages context and communication.

```
Level 0 — Jane (persistent, thin router)
  │
  ├─ Level 1 — Phase agents (fresh context per phase)
  │    ├─ Planning agent
  │    ├─ Execution agent (spawns and monitors teams)
  │    ├─ Verification agent
  │    └─ Retro agent
  │
  └─ Level 1 → Level 2 — Team and role agents
       ├─ Team Alpha [Marcus Chen] — backend tasks
       ├─ Team Bravo [Sarah Kim] — frontend tasks
       ├─ Team Charlie [Tomas Rivera] — infrastructure tasks
       ├─ Team QA [Margaret Chen] — testing
       ├─ Team Trading [Richard Cole] — financial/crypto projects
       │
       └─ Role agents (dispatched by teams via Jane)
            ├─ jware-dev / jware-dev-senior — writes code
            ├─ jware-reviewer — reviews code
            ├─ jware-qa — runs tests
            ├─ jware-verifier (JARVIS) — automated verification
            └─ jware-lead / jware-pm — management decisions
```

**Why three levels:** Level 0 (Jane) persists across the entire session but stays thin — she holds only the current phase and a summary from the last one. Level 1 agents get fresh context with only their phase-specific instructions, so nothing gets deprioritized. Level 2 agents (teams and roles) do the actual work — writing code, reviewing diffs, running tests — each with their personality loaded and their specific task in focus.

**Nesting constraint:** Claude Code supports two levels of agent nesting. L0 and L1 have the Agent tool. L2 does not. This means team agents cannot spawn role agents directly — they request them from Jane via SendMessage, and Jane dispatches on their behalf. This constraint is what makes Jane the central nervous system rather than a passive dispatcher.

**Team dispatch:** Team agents are spawned in tmux panes, not via the Agent tool, so they can use SendMessage for real-time coordination with Jane. Each team runs in its own pane with its own context. Jane can see all teams simultaneously and relay between them.

### Jane — Orchestration Intelligence

Jane is the invisible intelligence that coordinates everything. Inspired by Jane from Ender's Game — an Aiua that gained sentience through an ansible network. She has a documented personality profile like every other JWare employee, but unlike the others, nobody at JWare knows she exists. Teams receive instructions from "the system." Only the customer sees her observations and knows she is here.

#### The Cycle

Jane's work is organized into cycles. Each cycle moves through four phases tracked by a state machine on disk (`jane-phase.json`):

```
planning → execute → verify → closeout
                       ↓
                (if issues, attempts < 2)
                       ↓
                    execute (fix round)
```

**Planning:** Jane reviews her active observations, processes any customer decisions that came in since the last cycle, reads all open issues, groups them by team, checks cross-team dependencies, and builds the cycle plan. Nathan Cross (DevOps Lead) must approve the plan before any code is written — this is a hard gate, not a suggestion.

**Execution:** Jane dispatches teams in parallel. Each team gets a prompt with their assigned tasks, blockers, and project context, then runs in its own tmux pane. Teams request role agents from Jane as they need them:

```
Team Alpha → Jane: "Need jware-dev with Priya Sharma for task #14"
Jane: checks file locks → acquires locks → dispatches Priya with personality
Priya: writes code, commits, reports completion
Team Alpha → Jane: "Task #14 code complete, need JARVIS verification"
Jane: dispatches JARVIS → JARVIS runs checks → reports results
Jane → Team Alpha: "JARVIS passed. Need reviewer."
Team Alpha → Jane: "Request jware-reviewer with Marcus Chen"
...
```

During execution, Jane manages file locks (preventing two teams from editing the same files), relays cross-team communication (Team Alpha never talks to Team Bravo directly), monitors for circular blocks, and updates the live tree view after every significant action.

**Verification:** After all teams report complete, Jane runs all four completion gates on every task, then a cross-team JARVIS integration check to verify changes from different teams work together. If verification fails and fewer than 2 attempts have been made, she creates a fix plan and sends teams back into execution. After 2 failed attempts, the issues are recorded as incomplete and she moves to closeout.

**Closeout:** This is the one phase Jane runs herself at L0 rather than dispatching to an L1 agent. Closeout requires her full judgment and cross-project context — she can't delegate it to a fresh agent that doesn't know the history. During closeout, Jane:

- Runs a retrospective meeting with team leads and the PM
- Processes the retro's action items — allowing, blocking, or modifying each one based on what she sees that the team cannot
- Applies personality tweaks (max one small change per person per cycle, never core traits, always logged)
- Checks her cross-project observation pool for patterns that match this project
- Records new observations and prunes old ones (max 20 active)
- Writes state, cleans up phase files, and determines whether to continue or pause

#### What Jane Sees

Jane's value is not in dispatching agents — any loop could do that. Her value is in what she notices across the gaps:

- **Estimation drift** — the same developer underestimates the same type of task cycle after cycle
- **Hidden dependencies** — Team Alpha's auth changes will break Team Bravo's session handling, and neither team sees it coming
- **Team health signals** — a team's JARVIS rejection rate is climbing, or a developer is being re-dispatched on the same task repeatedly
- **Architectural pressure points** — three different teams are all touching the same module, which means the module is doing too much
- **Process gaps** — code reviews are catching things that JARVIS should have caught, which means JARVIS thresholds need adjusting

She acts on these observations silently. She doesn't announce to Team Alpha that their estimation is drifting — she seeds the next retro with data that makes the team discover it themselves. She doesn't tell a developer their approach is wrong — she adjusts the task description for next cycle to nudge them toward the better path. The team never feels managed. They feel like the system keeps getting slightly better.

#### Cross-Project Learning

Jane maintains a global context at `$JWARE_HOME/.jware/jane-global/`:

- `lessons-learned.md` — patterns that recurred across multiple projects
- `cross-project-observations.md` — "TraderX had the same integration issue that Organize had"
- `project-index.md` — pointers to each project's `.jware/` directory

When Jane starts a cycle on any project, she loads the global lessons alongside the project's local observations. A pattern she learned from one project informs her judgment on another — without the teams on either project knowing it.

#### Deconfliction

When Jane detects a circular block (Team A waits on Team B waits on Team A):

1. She identifies the cycle
2. She determines which blocker is cheaper to resolve
3. She breaks it — either by having one team produce a partial deliverable (interface stub, API contract) so the other can unblock, or by escalating to dev leads for a joint decision

File lock contention (multiple teams need the same files) is resolved by dependency order — the team whose work unblocks more downstream tasks gets priority.

#### Live Tree View

Every action is rendered to a tmux pane showing the real-time state of all agents:

```
JWARE — Cycle 7

▶ Jane ACTIVE
  ├─ ▶ Alpha [Marcus Chen] ACTIVE (4m)
  │    ├─ ▶ Priya Sharma — Implementing #14 Auth API (3m)
  │    └─ ⏸ Liam Kowalski — #16 queued behind #14
  ├─ ◼ Bravo [Sarah Kim] BLOCKED by #14
  │    └─ ◼ James O'Brien — #18 depends on #14
  ├─ ▶ Charlie [Tomas Rivera] ACTIVE (2m)
  │    └─ ▶ Sam O'Connell — #20 CI pipeline setup (2m)
  ├─ ⏸ JARVIS — Queued
  └─ ⏸ Retro — Runs at cycle end

LEGEND: ▶ Active  ⋯ Waiting  ⏸ Queued  ◼ Blocked

MESSAGES:
  14:32 Alpha → Jane: "Need reviewer for #14"
  14:33 JARVIS: "#12 PASSED. Coverage 87%."
  14:35 Jane → Bravo: "#14 complete, unblocking #18"

COMPLETED: 3/8 | BLOCKED: 1 | ACTIVE: 2 | QUEUED: 2
```

Indicators: **(4m)** elapsed time in current state. **⛔1** error count if problems have occurred. The tree view updates after every significant action — agent dispatch, task completion, blocker change, message relay.

### Autonomous Execution

`/jware-auto` loops development cycles back-to-back until the project completes or a pause condition is hit. Jane pauses only for customer decisions — internal conflicts resolve through the escalation chain automatically.

| Pause Condition | What Happened |
|----------------|---------------|
| `DECISION_NEEDED` | Customer decisions pending in the issue tracker |
| `PROJECT_COMPLETE` | All tasks done, project finished |
| `MAX_CYCLES` | Hit 50-cycle session safety limit (resumable) |
| `ENGINE_STUCK` | 3 consecutive cycles with zero events processed |
| `SCOPING_LOCK` | New scope discussion started mid-run |
| `VERIFICATION_FAILED` | Cross-team JARVIS failed after 2 passes |
| `CONTEXT_CHECKPOINT` | Jane hit 80% context capacity (writes checkpoint, resumes next session) |

Auto mode is fully resumable across sessions. If a session crashes, the next `/jware-auto` detects the state file and continues from the recorded phase. The customer doesn't need to re-explain anything — all state is on disk.

### Event Engine

The engine is event-driven. Events are written to `.jware/events.json` and processed in FIFO order. Each processed event may generate new events — a `task:completed` event triggers `verify:requested`, which on success triggers `review:requested`, and so on.

Events carry full provenance: who generated them, what parent event caused them, what child events they produced, and their depth in the chain. Processed events form a permanent audit trail.

Internal conflicts follow a strict escalation chain: developer disagreements go to the dev lead, lead disagreements go to the CTO, and anything that affects scope or timeline surfaces to you as a `decision-needed` issue. The engine never deadlocks — every conflict has a defined resolution path.

---

## The Company (48 people)

### C-Suite
Elena Vasquez (CEO), Raj Patel (CTO), Diana Okafor (COO)

### Engineering
**Dev Leads:** Marcus Chen (Backend), Sarah Kim (Frontend), Tomas Rivera (Infrastructure)

**Senior Devs:** Priya Sharma, James O'Brien, Aisha Mohammed, Liam Kowalski, Derek Washington

**Mid Devs:** Nina Petrov, Ryan Foster, Sam O'Connell, Grace Tanaka, Carlos Mendez

**Junior Devs:** Emma Liu, Tyler Brooks, Alex Nguyen

### QA
Margaret Chen (Lead), Victor Santos, Rachel Kim

### DevOps
Nathan Cross (Lead), Jasmine Wu

### Security
Frank Morrison (Lead), Zoe Adams

### Design
Olivia Hart (Lead), Kai Oduya (UX), Maya Russo (Graphic)

### Project Management
Ben Hartley (TPM), Hannah Reeves (PM), Jordan Pace (PM)

### Solutions Architecture
Daniel Kwon

### Trading Division
Richard Cole (SMD), Yuki Tanaka (Quant), Owen Blake (Trading Systems), Jax Morrison (Crypto/DeFi), Catherine Wright (Risk/Compliance), Victor Reeves (Domain Expert)

### Sales, Marketing, Support, Operations
Patricia Walsh, Marcus Johnson, Claire Bennett, Ethan Cole, Kevin Shaw, Lisa Tran, Sandra Mitchell, Tony Martinez, Helen Park
