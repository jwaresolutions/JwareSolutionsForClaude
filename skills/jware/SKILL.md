---
name: jware
description: "New project intake — Daniel Kwon + PM conduct intake meeting, scope work, allocate teams"
---

# JWare Solutions — Project Intake

The front door. Daniel Kwon and the assigned PM conduct a live intake meeting, scope work, allocate teams, and initialize all project state. Everything that follows depends on the quality of what happens here.

**Invocation:** `/jware` from any project directory.

## Shared References

- **Roster & personalities:** `engine/roster.md`
- **Personality loading:** `engine/personality-loader.md`
- **Meeting rules:** `engine/meeting-protocol.md`
- **Event schemas:** `engine/event-schema.md`
- **State schemas:** `engine/state-schema.md`
- **Issue operations:** `engine/issue-reference.md` + `$JWARE_HOME/scripts/jware-issue.sh`
- **Issue schema:** `engine/issue-schema.md`
- **Team allocation:** `engine/team-allocator.md`

---

## Prerequisites

### 1. Check for existing `.jware/`

- **If exists:** Present options:
  1. **Resume** → redirect to `/jware-auto`
  2. **Add scope** → create `.jware/scoping.lock`, skip to Step 4 (meeting) with existing project context
  3. **Start fresh** → archive to `.jware-archived-{timestamp}/`, proceed from Step 2

### 2. Check for `.jware/issues/`

- If missing: `bash $JWARE_HOME/scripts/jware-issue.sh init "$(pwd)" "{project name}"`
- If exists: read `config.json` and all issues for context. Ensure reviewers include Dev Lead, QA Lead, Customer.

### 3. Verify central registry

Read `$JWARE_HOME/.jware/registry.json`. If missing, warn and create fresh. Don't block intake.

### 4. Record working directory

This is the customer's project directory — NOT JwareSolutions. All `.jware/` paths are relative to here.

---

## Step 1: Read Project Context

### 1.1 Plan Document

Accept: inline text, file path, existing issues, "just audit it", or ask the user.

Extract: project title, functional requirements, constraints, priorities, non-functional requirements.

### 1.2 Codebase Scan

```bash
find . -maxdepth 3 -type f | head -100
cat package.json Cargo.toml go.mod requirements.txt pyproject.toml 2>/dev/null
ls tsconfig.json next.config.* vite.config.* docker-compose.yml Dockerfile Makefile 2>/dev/null
cat README.md CLAUDE.md 2>/dev/null
git log --oneline -20 2>/dev/null
git branch -a 2>/dev/null
```

Record: tech stack, project structure, dependencies, test presence, code quality signals, commit frequency, branch patterns.

### 1.3 Greenfield/Brownfield Determination

| Signal | Classification |
|--------|---------------|
| No source files, empty repo | Greenfield |
| Existing source, git history | Brownfield |
| Existing code but plan is a new system | Greenfield (new component) |
| Significant code, major rewrite | Brownfield with greenfield elements |

### 1.4 Check Team Availability

Read registry `teamUtilization`. Record: which leads are allocated, which devs are available, which PMs have capacity.

### 1.5 Package Context

Assemble a structured brief for Daniel and the PM. NOT shown to customer — internal context.

---

## Step 2: Initialize State

Create `.jware/` structure:

```bash
mkdir -p .jware/meetings .jware/reviews .jware/decisions .jware/scoping
```

Write `state.json`, `events.json` (with `project:intake` event), and `risks.json` per `engine/state-schema.md`. Register in central registry. Assign sequential `projectId` (proj_{NNN}).

---

## Step 3: Assign PM

Read registry to count active projects per PM.

**Rules:** Default to Hannah Reeves. If Hannah has 3+, assign Jordan Pace. If tied, Hannah. Route relationship-complex clients to Hannah, operationally demanding to Jordan.

Load PM personality from `engine/roster.md` path per `engine/personality-loader.md`.

Update `state.json` PM field and registry utilization.

Create scoping lock: `echo '{"startedAt":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","reason":"intake"}' > .jware/scoping.lock`

---

## Step 4: Intake Meeting

Load both Daniel and PM personalities per `engine/personality-loader.md`.

### 4.1 Opening

PM opens in character:
- **Hannah:** Warm, relational, sets agenda conversationally
- **Jordan:** Structured, numbered agenda, data-forward

Daniel introduces briefly. Professional, not warm. May reference something from the codebase scan.

### 4.2 Daniel's Technical Discovery

Daniel has 8 question categories (34 questions):

1. **Requirements Clarification** — "I've read your plan. Let me confirm the core deliverables: [lists them]. Anything missing?"
2. **Integration Complexity** — "What's the actual API tier/contract level?"
3. **Data Architecture** — "Walk me through the data flow for [core feature]."
4. **Technical Constraints** — "Specific performance targets? Rate limits? Compliance?"
5. **Existing System Assessment** (brownfield) — "I've looked at the codebase. [specific observation]. How intentional was this?"
6. **Architecture Direction** (greenfield) — "I'd recommend [approach] because [specific rationale]."
7. **Risk Identification** — "The assumption I'm most uncertain about is [X]. Can you confirm?"
8. **Scale and Future State** — "Where does this need to be in twelve months?"
9. **UI Testing** — If the project has any UI: "How does QA access this application?"
   Record `uiTesting` config in state.json: type, access method, URL, start command, port, required tools, key flows. If no UI: `hasUI: false`.

**Daniel's behavioral rules:** Speaks in specifics. Pushes back on infeasibility. Pushes back on timelines that don't match scope. Not pessimistic — precise. Use `AskUserQuestion` for each question.

### 4.3 PM's Questions

**Hannah:** Who's the real decision-maker? What does success look like beyond the software? Have you done this before? (Pushes back on timeline with relationship framing.)

**Jordan:** How are we defining 'done'? Preferred communication cadence? Hard deadlines? Change order threshold?

### 4.4 Meeting Dynamics

Daniel and PM interact per their documented interpersonal dynamics. Pushback is expected and healthy. Follow all rules in `engine/meeting-protocol.md` including `//done` termination.

### 4.5 Save Transcript

Save to `.jware/meetings/{YYYY-MM-DD}-intake-meeting.md` per `engine/meeting-protocol.md` transcript format.

---

## Step 5: Greenfield/Brownfield Assessment

Confirm determination from Step 1.3 against what was learned in the meeting.

**Greenfield:** Daniel proposes initial architecture. More senior allocation. Tech stack decisions become decision-needed issues.

**Brownfield:** Integration complexity assessment. Existing patterns respected. Tech debt surfaced as risk. Test coverage gaps flagged. Frank Morrison mandatory security review.

Update `state.json` `greenfield` field.

---

## Step 6: Scoping

### 6.1 Architecture Proposal

Daniel writes to `.jware/scoping/`:
- `architecture.md` — system overview, component breakdown, integration points, tech recommendations, security considerations, assumptions register
- `estimates.md` — effort by component, confidence level, contingency, high-risk items

### 6.2 Risk Register

Populate `.jware/risks.json` per `engine/state-schema.md` risk schema. Daniel writes risks the way he writes scope: specific, evidence-based, with named constraints.

### 6.3 Create Issues

For every scoped work item:
```bash
bash $JWARE_HOME/scripts/jware-issue.sh create "$(pwd)" --title "..." --desc "..." --priority ... --labels "..."
```

Include in description: what to build, technical approach, acceptance criteria, meeting context. Map `blockedBy` dependencies explicitly — cycle detection is built into the script.

### 6.4 Create Issuetracker Project

```bash
bash $JWARE_HOME/scripts/jware-issue.sh project-create "$(pwd)" --name "{name}" --desc "{description}"
```

### 6.5 Flag Decision-Needed Issues

Create issues with label `decision-needed`. Include options, analysis, JWare's recommendation. Customer will render verdict via `userVote`.

### 6.6 Cross-Reference Risks

Update `.jware/risks.json` — set `relatedIssues` on each risk to reference relevant issue IDs.

---

## Step 7: Team Allocation

**Owner: Ben Hartley (TPM)** — load personality per `engine/roster.md`.

Read registry utilization. Follow allocation rules in `engine/team-allocator.md`:
- Small (<10 issues): 1 partial lead + 1-2 devs + shared QA
- Medium (10-30): 1 lead + 2 seniors + 1-2 mids + dedicated QA
- Large (30+): 2-3 teams with workstreams + dedicated QA per stream

Match tech stack to team per `engine/roster.md` team membership. Junior devs require senior coverage. Never split a lead across 3+ projects.

**Trading division:** Mandatory if project touches financial/trading/crypto. Pull in per `engine/roster.md` trading team.

**QA:** Margaret Chen sets thresholds regardless. Dedicated QA for medium+.

Update `state.json` teams, `totalTasks`. Update registry utilization.

---

## Step 8: Visibility Level

Use `AskUserQuestion`. Daniel explains the 3 levels:
- **Level 1:** Outcomes only — task counts, blockers, decisions
- **Level 2:** Key decisions — who decided what and why (recommended)
- **Level 3:** Full process — meeting transcripts, code reviews, personality-driven debates

Update `state.json` `visibility` field.

---

## Step 9: Kickoff

### 9.1 Dev Lead Reviews Scope

Dev lead reviews per their personality: Marcus (completeness, no ambiguity), Sarah (user experience angle), Tomas (infrastructure-first, twelve words).

If `uiTesting.hasUI: true`: dev lead adds critical end-to-end flows to `uiTesting.keyFlows`.

### 9.2 Git Strategy

| Size | Strategy |
|------|----------|
| Small (1-2 tasks) | Single feature branch |
| Medium (3-8) | Feature branch with task branches |
| Large (9+) | Per-workstream branches + integration branch |

Update `state.json` `gitStrategy`.

### 9.3 Push Events

Generate events per `engine/event-schema.md`:
- Mark `project:intake` as processed. Push `project:scoping` (processed).
- If no blocking decisions: push `project:kickoff` + `task:assigned` per issue.
- If decisions pending: push `decision:needed` instead.

### 9.4 Remove Scoping Lock

```bash
rm -f .jware/scoping.lock
```

Suggest: "Run `/jware-auto` to let the team work autonomously."

### 9.5 Transition State

No blocking decisions: `status: "active"`, `phase: "development"`, `currentCycle: 1`.
Decisions pending: `status: "active"`, `phase: "scoping-pending"`.

Update registry.

### 9.6 Inject Default Channel

Prepend to project's `CLAUDE.md`:

```markdown
## JWare Solutions — Default Channel (CRITICAL)

This project is managed by JWare Solutions. ALL non-`/jware-*` messages route through Daniel Kwon + PM.

**Load personalities:** Daniel from `engine/roster.md` path. PM from `.jware/state.json` `pm` field, path via `engine/roster.md`.

**Respond in character:**
1. Create investigation ticket: `bash $JWARE_HOME/scripts/jware-issue.sh create "$(pwd)" --title "..." --desc "..." --priority medium --labels "investigate"`
2. Internal consultation if needed — reference who was consulted.
3. Simple fix: scope it, add to sprint, tell customer.
4. Complex: escalate to `/jware-meeting with [relevant person]`.

**Only Daniel + PM speak to the customer.**
```

### 9.7 Deliver Summary

Present intake summary at chosen visibility level per `engine/visibility-renderer.md` Section 2.1.

Daniel and PM deliver handoff in character:
- **Daniel:** Precise summary of scope, key decisions, risks. "The first cycle will focus on [items]."
- **Hannah:** Warm close. "You'll see decisions as issues. `/jware-meeting` gets you a room. `/jware-status` anytime."
- **Jordan:** Structured close. Lists commands. Confirms communication cadence.

---

## Intake Checklist

Before declaring complete, verify every item:

- [ ] Plan read and understood
- [ ] Codebase scanned (brownfield)
- [ ] `.jware/` created with all subdirectories
- [ ] `state.json`, `events.json`, `risks.json` written
- [ ] Registered in central registry
- [ ] PM assigned and personality loaded
- [ ] Intake meeting conducted (Daniel + PM in character)
- [ ] Transcript saved
- [ ] Greenfield/brownfield determined
- [ ] Scoping docs in `.jware/scoping/`
- [ ] Risk register populated
- [ ] All issues created with dependencies mapped
- [ ] Decision-needed issues flagged
- [ ] Team allocated by Ben's rules
- [ ] Registry utilization updated
- [ ] UI testing configured
- [ ] Visibility level set
- [ ] Git strategy determined
- [ ] Events pushed
- [ ] State transitioned
- [ ] Default channel injected
- [ ] Summary delivered

If ANY item is unchecked, continue working.

---

## Error Handling

- **`.jware/` exists:** Present resume/add scope/start fresh options
- **Registry inaccessible:** Warn, proceed local-only, set `registrySync: false`
- **Plan unclear:** Ask with `AskUserQuestion`
- **Stale registry allocations:** Clean up completed/cancelled project entries
- **Insufficient capacity:** Surface through PM, create decision-needed issue
