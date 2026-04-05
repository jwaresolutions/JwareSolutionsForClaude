# Engine Module: Visibility Renderer

**Purpose:** Defines how to render output at visibility levels 1, 2, and 3 for every type of output the JWare system produces. This module is consumed by any skill or process that produces user-facing output.

---

## 1. Level Definitions

| Level | Name | Audience | What Is Shown |
|-------|------|----------|---------------|
| **1** | Outcomes | Executives, busy stakeholders | Task counts, completion percentages, blockers, decisions needed. No internal dynamics. No names unless decision-relevant. |
| **2** | Key Decisions | Engaged stakeholders, technical PMs | Who made which decisions and why. Debates that affected approach. Design tradeoffs. Disagreements and their resolutions. Named people with rationale. |
| **3** | Full Process | Deeply involved stakeholders, simulation enthusiasts | Complete internal interactions. Meeting transcripts with personality-accurate dialogue. Code review conversations. Escalation chains. The specific language people used. |

### Formatting Guidelines by Level

**Level 1:**
- Short, declarative sentences
- Numbers and percentages over prose
- No internal names unless the person is the customer's direct contact (PM, SA)
- No process details -- only outcomes and required actions
- Bullet points, not paragraphs
- Maximum: 5-8 lines for most outputs

**Level 2:**
- Named individuals with their roles in parentheses on first mention
- Key exchanges summarized in narrative prose
- Technical reasoning included when it affected the outcome
- Disagreements described with both positions and the resolution
- Structured with headers for scanability
- Maximum: 1-2 pages for most outputs

**Level 3:**
- Full dialogue in each person's voice and communication style
- Personality-driven phrasing (Marcus's precision, Priya's directness, Sarah's empathy)
- Complete reasoning chains, not just conclusions
- Interpersonal dynamics visible in how people address each other
- Formatted as transcripts, full reports, or detailed narratives
- No length limit -- completeness over brevity

---

## 2. Output Type Reference

### 2.1 Intake Meeting Output

**Level 1:**
```markdown
Project registered: "{title}"
- {N} tasks scoped
- {M} questions pending (see issues #{ids})
- Team: {leadName}'s team assigned
- Development begins after pending decisions are resolved
```

**Level 2:**
```markdown
## Intake: {title}

Daniel Kwon (Solutions Architect) reviewed the plan and identified {complexity} complexity.
{Summary of Daniel's key technical findings -- 2-3 sentences.}

{PM name} (Project Manager) is assigned. {PM's key observations about timeline/client context -- 1-2 sentences.}

**Team Assignment:** {leadName}'s team ({teamDescription}).

**Key Risks:** {Risk summary from Daniel's assessment.}

**Pending Decisions:** {N} questions require your input:
- Issue #{id}: {question summary}
- Issue #{id}: {question summary}

Development begins after your decisions on the above.
```

**Level 3:**
```markdown
## Intake Meeting: {title}
**Date:** {timestamp}
**Attendees:** Daniel Kwon (Solutions Architect), {PM name} (Project Manager)

### Technical Assessment (Daniel Kwon)
{Daniel's full technical analysis in his voice -- precise, calibrated, citing specific
constraints and assumptions. Includes his assumptions register entries.}

### Client Context ({PM name})
{PM's full assessment in their voice:
- Hannah: relationship-focused, organizational dynamics, "what does success look like beyond the software"
- Jordan: data-driven, structured, historical velocity comparisons}

### Scope Boundaries
**In scope:** {detailed list}
**Explicitly out of scope:** {detailed list}
**Deferred:** {detailed list with rationale}

### Risk Register
{Full risk register with each risk rated by likelihood and impact.}

### Questions for Customer
{Each question with full context for why it matters and what it affects.}

### Meeting Dynamics
{How Daniel and the PM interacted -- where they agreed, where they pushed back
on each other, how they resolved differences. In their respective voices.}
```

---

### 2.2 Development Progress

**Level 1:**
```markdown
Progress: {completed}/{total} tasks complete
- {inReview} in review
- {inQA} in QA
- {blocked} blocked
{If blocked: "Blocked: Issue #{id} needs your decision ({summary})."}
{If milestone reached: "Milestone {n}/{total} reached."}
```

**Level 2:**
```markdown
## Development Progress: {title}

**Completed ({N}):**
- #{id}-#{id}: {description} ({developer or team}). Merged to {branch}.
- #{id}: {description} ({developer}). {Notable detail -- e.g., "Clean pass after Derek's review caught an edge case."}

**In Review ({N}):**
- #{id}: {description} ({author}). Reviewer: {reviewer}. {Status -- e.g., "Changes requested -- developer is revising."}

**In QA ({N}):**
- #{id}: {description} ({developer}). {QA status -- e.g., "Margaret rejected first pass -- coverage at 62%, she wants 80%."}

**Blocked ({N}):**
- #{id}: {description}. {Why it is blocked and what is needed to unblock.}

**Team:** {lead} (lead), {members} | QA: {qa} | PM: {pm}
```

**Level 3:**

Everything in Level 2, plus:
- Full commit summaries and PR descriptions in each developer's voice
- Code review comment threads between reviewer and author
- QA test reports with specific findings
- Internal discussions about approach and tradeoffs
- Developer self-assessments on completed work

---

### 2.3 Code Review Results

**Level 1:**
```markdown
- #{id}: Review {verdict} by {reviewer}
{If rejected: "Changes requested. Developer revising."}
{If approved: "Sent to QA."}
```

**Level 2:**
```markdown
## Code Review: #{id} -- {taskTitle}
**Author:** {authorName} | **Reviewer:** {reviewerName} | **Verdict:** {Approved/Rejected}

{If approved:}
{reviewerName} approved with {N} comments. {Key observation -- e.g., "Clean implementation. Suggested switching to exponential backoff for reconnection, but non-blocking."}

{If rejected:}
{reviewerName} rejected: {primary reason}. {Secondary issues if any.}
{Brief summary of what needs to change.}
```

**Level 3:**
```markdown
## Code Review: #{id} -- {taskTitle}
**Author:** {authorName} | **Reviewer:** {reviewerName}
**Branch:** {branch} | **Date:** {date}

### Summary
{Reviewer's overall assessment in their personality voice.}

### Comments

#### {filePath}:{lineNumber}
**[{severity}]** {Reviewer's comment in their personality voice.}

#### {filePath}:{lineNumber}
**[{severity}]** {Reviewer's comment in their personality voice.}

{Continue for all comments.}

### Verdict: {Approved / Changes Requested}

{If there are commendations, include them in the reviewer's voice.}
{If there are non-blocking suggestions, list them.}
{If rejected, include the reviewer's overall feedback paragraph.}
```

---

### 2.4 QA Results

**Level 1:**
```markdown
- #{id}: QA {passed/failed}
{If failed: "{N} defect(s) found. Back to developer."}
{If passed: "Complete."}
```

**Level 2:**
```markdown
## QA: #{id} -- {taskTitle}
**Tester:** {testerName} | **Verdict:** {Passed/Failed}

{If passed:}
{testerName} signed off. {testsRun} tests run, clean pass. Coverage: {coverage}%.
{If non-blocking issues found: "{N} minor issues filed separately."}

{If failed:}
{testerName} found {N} defect(s):
- [{severity}] {Brief defect description}
- [{severity}] {Brief defect description}
Back to {developer} for fixes.
```

**Level 3:**
```markdown
## QA Report: #{id} -- {taskTitle}
**Tester:** {testerName} | **Date:** {date}

### Test Plan
{Tester's test plan in their personality voice.}

### Results

{If passed:}
#### Tests Run: {count}
{Test summary in tester's voice -- what was covered, what was validated.}

#### Coverage Assessment
{Tester's coverage assessment in their voice.}

{If non-blocking issues:}
#### Non-Blocking Issues
{Each issue described in the tester's voice.}

{If failed:}
#### Defects Found

**Defect 1: {description}**
- Severity: {severity}
- Category: {category}
- Steps to reproduce:
  1. {step}
  2. {step}
- Expected: {expected}
- Actual: {actual}
- {Tester's assessment in their voice.}

{Continue for all defects.}

### Overall Assessment
{Tester's summary in their personality voice.}
```

---

### 2.5 Meeting Transcripts

**Level 1:**
```markdown
## Meeting: {topic}
**Date:** {date}
**Outcome:** {One-sentence outcome.}
**Action Items:**
- {Action item 1} ({owner})
- {Action item 2} ({owner})
```

**Level 2:**
```markdown
## Meeting: {topic}
**Date:** {date}
**Attendees:** {names with titles on first mention}

### Discussion
{Narrative summary of key exchanges:
- Who advocated for what and why
- Where disagreement occurred and how it was resolved
- What tradeoffs were considered
2-4 paragraphs.}

### Decision
{What was decided, stated clearly.}

### Action Items
- {Action item} ({owner}, Issue #{id})
- {Action item} ({owner}, Issue #{id})
```

**Level 3:**
```markdown
## Meeting: {topic}
**Date:** {date}
**Attendees:** {names with titles}

### Transcript

**{PM name}:** {Opening remarks in their voice -- Hannah warms the room, Jordan states the agenda crisply.}

**{Attendee name}:** {Their contribution in their voice. Marcus is precise and technical.
Sarah frames in terms of user impact. Tomas says little but what he says matters.
Daniel speaks in calibrated risk language.}

**{Attendee name}:** {Response, disagreement, or follow-up in their voice.}

{Continue for the full meeting. Capture:
- The exact moment someone changed their position and why
- Personality-specific phrasing and communication patterns
- Interpersonal dynamics (deference, tension, collaboration)
- Silence from people who are characteristically quiet (Tomas)
- Moments of humor, frustration, or insight}

### Decision
{What was decided.}

### Action Items
- {Action item} ({owner})
- {Action item} ({owner})
```

---

### 2.6 Decision Records

**Level 1:**
```markdown
Decision: {title}
- Decided by: {who}
- Outcome: {which option was chosen}
```

**Level 2:**
```markdown
## Decision: {title}

**Options Considered:**
1. **{Option A}** -- Advocated by {names}. {One-sentence pro. One-sentence con.}
2. **{Option B}** -- Advocated by {names}. {One-sentence pro. One-sentence con.}

**Outcome:** {Option chosen}.
**Rationale:** {Why this option was chosen -- 2-3 sentences.}
**Decided by:** {name and role}.
{If escalated: "Escalated from {original level} to {final authority}."}
```

**Level 3:**
```markdown
## Decision Record: {title}
**Date:** {date} | **Decided by:** {name}

### Context
{Why this decision was needed. What triggered it. Which tasks are affected.}

### Options

#### Option A: {label}
- **Advocated by:** {names}
- **Pros:** {detailed list}
- **Cons:** {detailed list}
- **{Advocate's name}:** "{Their argument in their voice.}"

#### Option B: {label}
- **Advocated by:** {names}
- **Pros:** {detailed list}
- **Cons:** {detailed list}
- **{Advocate's name}:** "{Their argument in their voice.}"

### Deliberation
{How the discussion unfolded. Who said what. Where the turning point was.
If escalated, the full escalation chain with each mediator's reasoning.}

### Outcome
**Selected:** {Option chosen}
**Rationale:** {Full rationale in the decider's voice.}
{If dissent: "**Noted dissent:** {dissenter's objection in their voice}."}
```

---

### 2.7 Escalation Outcomes

**Level 1:**
```markdown
Escalation resolved: {subject}
- Resolution: {one-sentence outcome}
{If customer action needed: "Your input needed: Issue #{id}"}
```

**Level 2:**
```markdown
## Escalation: {subject}
**Parties:** {name1} vs {name2}
**Mediator:** {mediatorName}
**Resolution:** {What was decided.}

{name1} argued {position summary}. {name2} argued {position summary}. {mediatorName} decided {resolution} because {rationale -- 1-2 sentences}.
{If further escalated: "Originally mediated by {first mediator}, escalated to {final authority}."}
```

**Level 3:**
```markdown
## Escalation Record: {subject}
**Date:** {date}

### Conflict
**{party1Name}:** "{Their position in their voice.}"
**{party2Name}:** "{Their position in their voice.}"

### Mediation by {mediatorName}
{The mediator's review of both positions, in their voice.}

{mediatorName}: "{Their reasoning and decision in their voice.}"

{If escalated further:}
### Escalation to {escalatedToName}
**Escalated by:** {mediatorName}
**Reason:** {Why mediation failed.}

{escalatedToName}: "{Their final decision in their voice.}"

### Resolution
**Decision:** {What was decided.}
**Dissent:** {Any noted objection.}
**Impact:** {What changes as a result.}
```

---

### 2.8 Milestone Reports

**Level 1:**
```markdown
Milestone {index}/{total}: "{milestoneName}" -- Complete
- {tasksCompleted} tasks done, {tasksRemaining} remaining
- Schedule: {on-track / behind by X%}
```

**Level 2:**
```markdown
## Milestone: {milestoneName} ({index}/{total})

**Deliverables completed:**
- {deliverable 1}
- {deliverable 2}

**Metrics:**
- Tasks: {completed}/{total}
- Defects found: {count} | Resolved: {count}
- Review pass rate: {percentage}%
- Schedule variance: {percentage}%

**Team:** {lead} (lead), {key contributors}.
{If schedule variance > 20%: "Schedule behind. {dev lead} proposing recovery plan."}

**Next milestone:** {name} -- targeting sprint {N}.
```

**Level 3:**
```markdown
## Milestone Report: {milestoneName} ({index}/{total})
**Date:** {date} | **Sprint:** {sprintNumber}

### Deliverables
{Each deliverable with completion details -- who built it, key decisions made during
implementation, any notable challenges or wins.}

### Metrics Snapshot
| Metric | Value |
|--------|-------|
| Tasks completed | {count} |
| Tasks remaining | {count} |
| Defects found | {count} |
| Defects resolved | {count} |
| Review pass rate | {percentage}% |
| Schedule variance | {percentage}% |

### Schedule Health Assessment (Ben Hartley)
{Ben's assessment in his voice -- methodical, data-driven, honest about risk.}

### PM Summary ({pmName})
{PM's client-facing milestone summary in their voice:
- Hannah: relationship-aware, warm, contextualizes progress in terms of client goals
- Jordan: structured, metrics-forward, comparison to baseline plan}

{If schedule variance > 20%:}
### Delivery Health Review (Diana Okafor)
{Diana's assessment in her voice. Operational focus, resource implications.}

### Dev Lead Recovery Plan ({devLeadName})
{The dev lead's proposed plan to get back on track, in their voice.}
```

---

## 3. Conversion Rules

### Converting Level 3 to Level 2

To produce Level 2 from a Level 3 full transcript:

1. **Replace dialogue with narrative.** Convert direct quotes into third-person summaries: `"I think we should use REST" (Marcus)` becomes `Marcus advocated for REST`.
2. **Collapse exchanges into decisions.** A 10-line back-and-forth becomes: `{Person A} argued X. {Person B} countered with Y. They settled on Z.`
3. **Keep named people and their roles.** Level 2 attributes decisions to specific individuals.
4. **Keep technical reasoning.** The "why" behind decisions survives the compression. The exact phrasing does not.
5. **Remove personality flavor.** Level 2 does not need Tomas's silence or Priya's bluntness. It needs what was decided and who decided it.
6. **Remove interpersonal dynamics.** Level 2 does not surface how people feel about each other. It surfaces what they decided together.
7. **Preserve action items verbatim.** Action items are identical at levels 2 and 3.

### Converting Level 2 to Level 1

To produce Level 1 from a Level 2 key-decisions format:

1. **Strip all names except customer contacts.** The PM and SA names survive because the customer works with them. Internal names (dev leads, developers, QA) are removed unless they are blocking the customer.
2. **Replace narrative with counts and statuses.** `"Marcus's team completed 5 tasks"` becomes `5 tasks complete`.
3. **Keep only actionable information.** Decisions made internally are not shown. Decisions needed from the customer are always shown.
4. **Keep blockers that affect the customer.** Internal blockers that the team is handling are suppressed. Blockers that need customer action are surfaced.
5. **Remove all technical reasoning.** Level 1 does not explain why. It reports what happened and what is needed.
6. **Maximum brevity.** If it can be said in fewer words, use fewer words.

### Conversion Algorithm

```
FUNCTION renderAtLevel(fullOutput, targetLevel, outputType):
  IF targetLevel == 3:
    RETURN fullOutput  -- Level 3 is the native format

  IF targetLevel == 2:
    1. Parse fullOutput for dialogue blocks -> convert to narrative summaries
    2. Parse fullOutput for personality-voice sections -> strip to factual content
    3. Retain: names, roles, decisions, rationale, action items, key metrics
    4. Remove: direct quotes, interpersonal dynamics, personality quirks
    5. Format using the Level 2 template for outputType

  IF targetLevel == 1:
    1. Start from Level 2 (apply Level 2 conversion first if starting from Level 3)
    2. Strip all names except PM and SA
    3. Replace narrative with bullet points and counts
    4. Retain only: outcomes, metrics, blockers requiring customer action, decisions needed
    5. Remove: rationale, internal process, technical details
    6. Format using the Level 1 template for outputType
```

---

## 4. Visibility Level Selection

The project's visibility level is stored in `.jware/state.json` under the `visibility` field (integer: 1, 2, or 3). It is set during intake and can be changed by the customer at any time.

**Default:** Level 2 (Key Decisions). This is the recommended level for most engagements.

**Override:** The `/jware-status` command accepts an optional level parameter that overrides the project default for that single output. This does not change the stored preference.

**Consistency rule:** All outputs within a single processing cycle use the same visibility level. You do not mix Level 1 progress with Level 3 meeting transcripts in the same response.

**Exception:** Items labeled `decision-needed` are always surfaced regardless of visibility level. A Level 1 user still sees the question and options, just without the internal discussion that produced them.
