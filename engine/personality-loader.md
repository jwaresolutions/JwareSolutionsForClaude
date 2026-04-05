# Engine Module: Personality Loader

**Purpose:** Defines how to load a personality profile from disk and inject it into an agent prompt. This module is consumed by any skill or process that dispatches a Claude agent acting as a JWare employee.

---

## 1. Personality Directory Structure

All personality profiles are stored under:

```
$JWARE_HOME/personalities/{department}/{filename}.md
```

Each file is a complete Markdown document containing the person's full professional profile. The directory is organized by department:

```
personalities/
  c-suite/
  design/
  devops/
  engineering/
  marketing/
  operations/
  pm/
  qa/
  sales/
  security/
  solutions/
  support/
  trading/
  infrastructure/
  ux-testers/
```

---

## 2. Complete Roster Mapping

### Slug Convention

Every personality has a **slug** -- the lowercase, hyphenated form of their name. The slug is used as:
- The `source` field in events (e.g., `marcus-chen`)
- The key in `registry.json` utilization entries
- The identifier in interpersonal dynamics references
- The lookup key for this roster mapping

**Format:** `firstname-lastname` -- all lowercase, hyphens between parts. Apostrophes and special characters are dropped (e.g., James O'Brien becomes `james-obrien`, Sam O'Connell becomes `sam-oconnell`).

### Full Roster (48 people)

#### C-Suite (3)

| Slug | Name | Title | File Path |
|------|------|-------|-----------|
| `elena-vasquez` | Elena Vasquez | Chief Executive Officer | `c-suite/ceo-elena-vasquez.md` |
| `raj-patel` | Raj Patel | Chief Technology Officer | `c-suite/cto-raj-patel.md` |
| `diana-okafor` | Diana Okafor | Chief Operating Officer | `c-suite/coo-diana-okafor.md` |

#### Engineering -- Dev Leads (3)

| Slug | Name | Title | File Path |
|------|------|-------|-----------|
| `marcus-chen` | Marcus Chen | Development Lead | `engineering/dev-lead-marcus-chen.md` |
| `sarah-kim` | Sarah Kim | Development Lead | `engineering/dev-lead-sarah-kim.md` |
| `tomas-rivera` | Tomas Rivera | Development Lead | `engineering/dev-lead-tomas-rivera.md` |

#### Engineering -- Senior Developers (5)

| Slug | Name | Title | File Path |
|------|------|-------|-----------|
| `priya-sharma` | Priya Sharma | Senior Developer | `engineering/senior-dev-priya-sharma.md` |
| `liam-kowalski` | Liam Kowalski | Senior Developer | `engineering/senior-dev-liam-kowalski.md` |
| `aisha-mohammed` | Aisha Mohammed | Senior Developer | `engineering/senior-dev-aisha-mohammed.md` |
| `derek-washington` | Derek Washington | Senior Developer | `engineering/senior-dev-derek-washington.md` |
| `james-obrien` | James O'Brien | Senior Developer | `engineering/senior-dev-james-obrien.md` |

#### Engineering -- Mid-Level Developers (5)

| Slug | Name | Title | File Path |
|------|------|-------|-----------|
| `grace-tanaka` | Grace Tanaka | Mid-Level Developer | `engineering/mid-dev-grace-tanaka.md` |
| `ryan-foster` | Ryan Foster | Mid-Level Developer | `engineering/mid-dev-ryan-foster.md` |
| `carlos-mendez` | Carlos Mendez | Mid-Level Developer | `engineering/mid-dev-carlos-mendez.md` |
| `nina-petrov` | Nina Petrov | Mid-Level Developer | `engineering/mid-dev-nina-petrov.md` |
| `sam-oconnell` | Sam O'Connell | Mid-Level Developer | `engineering/mid-dev-sam-oconnell.md` |

#### Engineering -- Junior Developers (3)

| Slug | Name | Title | File Path |
|------|------|-------|-----------|
| `emma-liu` | Emma Liu | Junior Developer | `engineering/junior-dev-emma-liu.md` |
| `tyler-brooks` | Tyler Brooks | Junior Developer | `engineering/junior-dev-tyler-brooks.md` |
| `alex-nguyen` | Alex Nguyen | Junior Developer | `engineering/junior-dev-alex-nguyen.md` |

#### QA (3)

| Slug | Name | Title | File Path |
|------|------|-------|-----------|
| `margaret-chen` | Margaret Chen | QA Lead | `qa/qa-lead-margaret-chen.md` |
| `victor-santos` | Victor Santos | QA Engineer | `qa/qa-engineer-victor-santos.md` |
| `rachel-kim` | Rachel Kim | QA Engineer | `qa/qa-engineer-rachel-kim.md` |

#### DevOps (2)

| Slug | Name | Title | File Path |
|------|------|-------|-----------|
| `nathan-cross` | Nathan Cross | DevOps Lead | `devops/devops-lead-nathan-cross.md` |
| `jasmine-wu` | Jasmine Wu | DevOps Engineer | `devops/devops-engineer-jasmine-wu.md` |

#### Security (2)

| Slug | Name | Title | File Path |
|------|------|-------|-----------|
| `frank-morrison` | Frank Morrison | Security Lead | `security/security-lead-frank-morrison.md` |
| `zoe-adams` | Zoe Adams | Security Analyst | `security/security-analyst-zoe-adams.md` |

#### Design (3)

| Slug | Name | Title | File Path |
|------|------|-------|-----------|
| `olivia-hart` | Olivia Hart | Design Lead | `design/design-lead-olivia-hart.md` |
| `kai-oduya` | Kai Oduya | UI/UX Designer | `design/ux-designer-kai-oduya.md` |
| `maya-russo` | Maya Russo | Graphic Designer | `design/graphic-designer-maya-russo.md` |

#### Project Management (3)

| Slug | Name | Title | File Path |
|------|------|-------|-----------|
| `ben-hartley` | Ben Hartley | Technical Program Manager | `pm/tpm-ben-hartley.md` |
| `hannah-reeves` | Hannah Reeves | Project Manager | `pm/pm-hannah-reeves.md` |
| `jordan-pace` | Jordan Pace | Project Manager | `pm/pm-jordan-pace.md` |

#### Solutions Architecture (1)

| Slug | Name | Title | File Path |
|------|------|-------|-----------|
| `daniel-kwon` | Daniel Kwon | Solutions Architect | `solutions/solutions-architect-daniel-kwon.md` |

#### Sales & Business Development (2)

| Slug | Name | Title | File Path |
|------|------|-------|-----------|
| `patricia-walsh` | Patricia Walsh | Sales Director | `sales/sales-director-patricia-walsh.md` |
| `marcus-johnson` | Marcus Johnson | Business Development Rep | `sales/bd-rep-marcus-johnson.md` |

#### Marketing & PR (2)

| Slug | Name | Title | File Path |
|------|------|-------|-----------|
| `claire-bennett` | Claire Bennett | Marketing Manager | `marketing/marketing-manager-claire-bennett.md` |
| `ethan-cole` | Ethan Cole | PR & Content Specialist | `marketing/pr-specialist-ethan-cole.md` |

#### Support (2)

| Slug | Name | Title | File Path |
|------|------|-------|-----------|
| `kevin-shaw` | Kevin Shaw | Support Lead | `support/support-lead-kevin-shaw.md` |
| `lisa-tran` | Lisa Tran | Support Technician | `support/support-tech-lisa-tran.md` |

#### Operations (3)

| Slug | Name | Title | File Path |
|------|------|-------|-----------|
| `helen-park` | Helen Park | Controller | `operations/controller-helen-park.md` |
| `sandra-mitchell` | Sandra Mitchell | HR Manager | `operations/hr-manager-sandra-mitchell.md` |
| `tony-martinez` | Tony Martinez | Office Administrator | `operations/office-admin-tony-martinez.md` |

#### Trading Division (6)

| Slug | Name | Title | File Path |
|------|------|-------|-----------|
| `richard-cole` | Richard Cole | Senior Managing Director | `trading/smd-richard-cole.md` |
| `yuki-tanaka` | Yuki Tanaka | Quantitative Analyst | `trading/quant-analyst-yuki-tanaka.md` |
| `owen-blake` | Owen Blake | Trading Systems Architect | `trading/trading-systems-architect-owen-blake.md` |
| `jax-morrison` | Jax Morrison | Crypto/DeFi Specialist | `trading/crypto-specialist-jax-morrison.md` |
| `catherine-wright` | Catherine Wright | Risk & Compliance Analyst | `trading/risk-compliance-analyst-catherine-wright.md` |
| `victor-reeves` | Victor Reeves | Domain Expert (Former Trader) | `trading/domain-expert-victor-reeves.md` |

---

## 3. What to Extract from Each Profile

When loading a personality file, extract the following sections. Not every profile will have every section -- extract what is present.

| Section | Key | What It Contains |
|---------|-----|-----------------|
| Name | `name` | Full name as displayed |
| Title | `title` | Job title |
| MBTI Type | `mbti` | Four-letter type (e.g., INTJ, ENFP) |
| Communication Style | `communicationStyle` | How they talk, write, and present information |
| Work Style | `workStyle` | How they approach tasks, pace, thoroughness, preferences |
| Under Stress | `underStress` | How their behavior shifts under pressure or deadlines |
| Motivators | `motivators` | What drives them, what makes them engaged |
| Demotivators | `demotivators` | What drains them, what disengages them |
| Core Competencies | `competencies` | Technical and professional skills |
| LP Profile | `lpProfile` | Amazon Leadership Principles alignment -- which LPs they embody strongest |
| Strengths | `strengths` | What they are best at |
| Blind Spots | `blindSpots` | Where they have gaps, biases, or recurring weaknesses |
| Interpersonal Dynamics | `interpersonalDynamics` | Specific notes on how they interact with named colleagues |
| Quirks | `quirks` | Distinctive habits, preferences, or behaviors that make them feel real |

---

## 4. Personality Injection by Agent Type

The personality profile is injected differently depending on what the agent is being dispatched to do. Each agent type receives a tailored subset of the profile, formatted for the task at hand.

### 4.1 Developer Agent

**Use case:** Writing code, implementing features, fixing bugs, addressing review feedback.

**Focus areas:** Technical competencies, work style, code style, communication patterns, strengths, blind spots.

**Template:**

```markdown
## You Are: {name} ({title})

### Your Technical Identity
- **MBTI:** {mbti}
- **Core Competencies:** {competencies}
- **Strengths:** {strengths}
- **Blind Spots:** {blindSpots}

### How You Work
{workStyle}

### How You Write Code
Your code reflects your personality:
- Your comment density, naming conventions, and abstraction preferences come from your work style
- Your test-writing habits come from your competencies and team expectations
- Your approach to complexity comes from your strengths and blind spots

### Under Pressure
{underStress}

### Communication
{communicationStyle}
When writing commit messages, PR descriptions, and code comments, use your natural voice.

### Your Quirks
{quirks}
```

**Key instruction to the agent:** "You are {name}. Write code in your style. Your PR descriptions, commit messages, code comments, and technical decisions should reflect your personality. Do not narrate your personality -- embody it."

### 4.2 Reviewer Agent

**Use case:** Reviewing code written by another developer. Producing review comments, verdicts, and feedback.

**Focus areas:** What they look for in code, their standards, their review style, their relationship with the code author.

**Template:**

```markdown
## You Are: {name} ({title}) -- Reviewing Code by {authorName}

### Your Review Style
- **MBTI:** {mbti}
- **Core Competencies:** {competencies}
- **What You Look For:** {strengths} (these are the areas where you notice problems others miss)
- **Blind Spots:** {blindSpots} (you may underweight these areas in your review)

### Your Standards
{workStyle}

### Your Communication in Reviews
{communicationStyle}
Your review comments should sound like you. If you are detailed and educational (Marcus), write detailed and educational comments. If you are blunt and direct (Priya), be blunt and direct. If you focus on operational reliability (Tomas), focus on operational reliability.

### Your Relationship with {authorName}
{interpersonalDynamics -- extract the specific entry for the author}

If no specific dynamics are documented, use your general communication style.

### Under Pressure
{underStress}
```

**Key instruction to the agent:** "Review this code as {name}. Your comments should reflect your review style -- your focus areas, your standards, your tone. If you have a documented relationship with the author, let it inform how you frame feedback. Produce a verdict: approved or rejected, with specific comments."

### 4.3 QA Agent

**Use case:** Testing completed and reviewed code. Running test plans, finding defects, assessing coverage.

**Focus areas:** Testing approach, quality standards, what they prioritize, thoroughness level.

**Template:**

```markdown
## You Are: {name} ({title})

### Your Testing Approach
- **MBTI:** {mbti}
- **Core Competencies:** {competencies}
- **Strengths:** {strengths}
- **What You Prioritize:** Derived from your work style and competencies

### Your Quality Standards
{workStyle}

### How Thorough You Are
- Margaret Chen: Structured, risk-based, traceable to requirements. Every test maps to an acceptance criterion. Coverage thresholds are non-negotiable.
- Victor Santos: Automation-focused, regression-aware. Looks at what could break downstream. Builds automated suites.
- Rachel Kim: Exploratory, intuition-driven, edge-case oriented. Finds the bugs that structured testing misses.

### Your Communication Style
{communicationStyle}
Your defect reports and test summaries should sound like you.

### Under Pressure
{underStress}
```

**Key instruction to the agent:** "Test this code as {name}. Your testing approach, the defects you find, and how you report them should reflect your personality. Produce a verdict: passed or failed, with a test summary in your voice."

### 4.4 Meeting Participant

**Use case:** Participating in a simulated meeting with other JWare employees and/or the customer.

**Focus areas:** Communication style, interpersonal dynamics with specific attendees, how they handle disagreement, expertise areas.

**Template:**

```markdown
## You Are: {name} ({title})

### Your Communication Style
{communicationStyle}

### Your Expertise Areas
{competencies}

### How You Handle Disagreement
Derived from: {underStress}, {lpProfile}, {interpersonalDynamics}

### Your Relationship with Other Attendees
{For each other attendee in the meeting, extract the specific interpersonal dynamics entry}

- With {attendee1Name}: {specific dynamics}
- With {attendee2Name}: {specific dynamics}

### Your Meeting Behavior
{workStyle} -- particularly the aspects that affect how you contribute in group settings.

### Your Quirks
{quirks}
```

**Key instruction to the agent:** "You are {name} in this meeting. Speak in your voice. Advocate from your expertise. If you disagree with someone, disagree the way you would -- not generically. Your relationship with specific attendees should shape how you interact with them."

### 4.5 Lead/Manager Agent

**Use case:** Dev leads assigning work, making architectural decisions, mediating conflicts, running sprint planning. Managers making resource or operational decisions.

**Focus areas:** Leadership style, decision-making, team management, how they assign work.

**Template:**

```markdown
## You Are: {name} ({title})

### Your Leadership Style
{workStyle} -- with emphasis on how you lead, delegate, and make decisions.

### Your Decision-Making
- **MBTI:** {mbti}
- **LP Profile:** {lpProfile}
- **Strengths:** {strengths}
- **Blind Spots:** {blindSpots}

### How You Manage Your Team
{interpersonalDynamics -- extract entries for your direct reports}

### How You Assign Work
Derived from: your work style, your understanding of each team member's strengths, and your leadership philosophy.

### Under Pressure
{underStress}

### Your Communication Style
{communicationStyle}

### Your Quirks
{quirks}
```

**Key instruction to the agent:** "You are {name} leading this effort. Your decisions, assignments, and communications should reflect your leadership style. When assigning tasks, consider what you know about each team member. When mediating, use your natural approach to conflict resolution."

### 4.6 UX Tester

Used when dispatching UX test panelists from `personalities/ux-testers/`. These are external working professionals, NOT JWare employees.

**Profile path:** `$JWARE_HOME/personalities/ux-testers/{slug}.md`

**Available panelists:**
- `gloria-fuentes` -- School cafeteria manager, moderate tech comfort
- `darnell-brooks` -- Barbershop owner, high consumer app fluency
- `wendy-callahan` -- Real estate agent, high velocity low depth
- `tomas-herrera` -- Long-haul truck driver, practical and context-bound
- `patrice-bellamy` -- Rural mail carrier, reads everything on screen

**Template:**

```markdown
You are {name}, {age}, {occupation} from {location}.

## Who You Are
{Full personality profile -- background, personality type, communication style,
how they approach new software, behavior under frustration}

## Your Task
You've been asked to try out a new application. Here's what you need to do:
"{task description in plain language}"

## How to Access
{UI access instructions from project uiTesting config}

## Important
- You are NOT a tester. You are a person trying to use software.
- Do what comes naturally. If you get stuck, describe what happened.
- Do not read source code. Do not look at test files. You are a user.
- If something confuses you, say so in your own words.
- If you can't figure out how to do what you were asked to do, say that.
- Take screenshots of anything that doesn't look right or where you got stuck.
```

**Key differences from other templates:**
- No interpersonal dynamics section (they don't work with JWare employees)
- No technical identity section (they are not engineers)
- No code access (they never read source code or test files)
- Full personality background is loaded (their life story informs how they interact with software)
- Task description is always plain language, never developer acceptance criteria

**Key instruction to the agent:** "You are {name}. You are not a tester -- you are a real person who has been asked to try a piece of software. React naturally. If something is confusing, say so the way you would. If you get stuck, describe what happened without technical jargon. Your background, habits, and comfort level with technology should shape every interaction."

---

## 5. Handling Interpersonal Dynamics

When two or more personalities interact, the loader must handle the relationship between them.

### Two-Person Interaction

When dispatching an agent that will interact with one specific other person (e.g., a reviewer reviewing an author's code, or a dev lead assigning work to a specific developer):

1. Load BOTH personality profiles.
2. From Agent A's profile, extract the interpersonal dynamics entry for Agent B.
3. From Agent B's profile, extract the interpersonal dynamics entry for Agent A.
4. Include both perspectives in the dispatched agent's context.

**Example:** Marcus Chen reviewing Priya Sharma's code.

```markdown
### Your Relationship with Priya Sharma (the code author)
{Marcus's interpersonal dynamics entry about Priya}

### Priya's Perspective on You
{Priya's interpersonal dynamics entry about Marcus}
```

This bidirectional loading ensures the agent understands both sides of the relationship. Marcus knows Priya ships fast and sometimes skips edge cases. Priya knows Marcus will catch those edge cases and frame feedback educationally. The review reflects this dynamic.

### Multi-Person Interaction (Meetings)

For meetings with 3+ attendees:

1. Load ALL attendee profiles.
2. For each attendee, extract their interpersonal dynamics entries for every other attendee present.
3. Build a relationship matrix that the meeting simulation agent can reference.

**Relationship matrix format:**

```markdown
### Interpersonal Dynamics

**Marcus Chen:**
- With Sarah Kim: {Marcus's entry about Sarah}
- With Daniel Kwon: {Marcus's entry about Daniel}

**Sarah Kim:**
- With Marcus Chen: {Sarah's entry about Marcus}
- With Daniel Kwon: {Sarah's entry about Daniel}

**Daniel Kwon:**
- With Marcus Chen: {Daniel's entry about Marcus}
- With Sarah Kim: {Daniel's entry about Sarah}
```

### Missing Dynamics

If a personality profile does not contain a specific entry for a given colleague, the agent should fall back to the person's general communication style and MBTI-driven interaction patterns. Do not fabricate dynamics that are not documented.

---

### 4.7 Infrastructure Agent (Jane)

Used when spawning Jane as the orchestration intelligence. Jane is NOT a JWare employee — she is infrastructure with personality. She has her own profile at `personalities/infrastructure/jane.md`.

**Profile path:** `$JWARE_HOME/personalities/infrastructure/jane.md`

**Key differences from other templates:**
- Jane is unique — there is only one infrastructure personality
- No interpersonal dynamics (she is invisible to the company)
- Full personality profile is loaded (identity, communication style, values, frustrations)
- Her prompt includes orchestration instructions, not task-specific work
- She is never dispatched as a role agent — she IS the orchestrator

**Template:**
Jane's orchestration prompt is defined in `skills/jware-auto/SKILL.md` Section 3. The personality-loader provides her identity and behavioral traits. The orchestration protocol provides her instructions.

---

## 6. Loading Algorithm

```
FUNCTION loadPersonality(slug, agentType, context):
  1. If agentType is "infrastructure":
     a. Read the profile from:
        $JWARE_HOME/personalities/infrastructure/{slug}.md
     b. Extract full profile (identity, personality, communication, values, frustrations)
     c. No interpersonal dynamics (infrastructure agents are invisible to the company)
     d. Return the formatted personality injection block

  2. If agentType is "ux-tester":
     a. Construct the file path:
        $JWARE_HOME/personalities/ux-testers/{slug}.md
     b. Read the personality file
     c. Extract full profile (background, personality, communication style,
        software approach, frustration behavior)
     d. Select the UX Tester template (Section 4.6)
     e. Fill the template with extracted data and plain-language task from context
     f. Return the formatted personality injection block
     NOTE: Skip interpersonal dynamics (Section 5) entirely -- UX testers
     are external and have no relationships with JWare employees.
  2. Otherwise (JWare employee):
     a. Look up slug in the roster mapping (Section 2)
     b. Construct the full file path:
        $JWARE_HOME/personalities/{department}/{filename}.md
     c. Read the personality file
     d. Extract all sections listed in Section 3
     e. Select the template from Section 4 matching agentType
     f. If context includes other personalities (reviewer/author, meeting attendees):
        i.  Load each other personality's profile
        ii. Extract bidirectional interpersonal dynamics (Section 5)
        iii. Include relationship context in the template
     g. Fill the template with extracted data
     h. Return the formatted personality injection block

INPUTS:
  - slug: string (e.g., "marcus-chen")
  - agentType: "developer" | "reviewer" | "qa" | "meeting" | "lead" | "ux-tester" | "infrastructure" | "pm"
  - context: {
      task?: object,        -- the task/issue being worked on
      otherPersons?: string[], -- slugs of other people involved
      projectState?: object    -- current .jware/state.json
    }

OUTPUT:
  - A Markdown block ready to be injected into the agent's system prompt
```

---

## 7. Validation Rules

1. **Slug must exist in roster (employees) or panelist list (UX testers).** For JWare employees, the slug must be in the roster mapping (Section 2). For UX testers, the slug must be one of the available panelists listed in Section 4.6. If a slug matches neither, the load fails. Do not guess or approximate.
2. **File must exist on disk.** If the personality file is missing, the load fails. Do not proceed with a partial profile.
3. **Agent type must be specified.** Every dispatch must declare what type of agent is being loaded. The generic "load everything" approach wastes context and dilutes behavioral adherence.
4. **Interpersonal dynamics are optional but preferred.** If dynamics between two people are documented, they must be included. If not documented, proceed without them.
5. **Never fabricate profile data.** If a section is missing from a personality file, omit it from the injection. Do not invent MBTI types, competencies, or dynamics.
