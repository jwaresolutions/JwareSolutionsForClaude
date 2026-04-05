# Engine Module: Team Allocator

**Purpose:** Defines Ben Hartley's team allocation logic -- how projects are matched to teams, how resources are assigned, and how the central registry is read and updated. This module is consumed by any skill or process that performs team allocation during intake, kickoff, or resource rebalancing.

**Owner:** Ben Hartley (TPM). All allocation decisions flow through Ben. He maintains the cross-project dependency map, checks utilization data, and enforces allocation constraints.

---

## 1. The Three Development Teams

### Marcus Chen's Team

**Specialization:** Backend-heavy, API-driven, data-intensive projects.

**Character:** Thorough PRs with detailed commit messages. High test coverage expectations -- Marcus rejects PRs with missing tests. Strong backend fluency (Node.js, Python, Go). Data-driven sprint planning.

| Slug | Name | Level | Strengths |
|------|------|-------|-----------|
| `marcus-chen` | Marcus Chen | Dev Lead | Backend architecture, API design, systems thinking, educational code reviews |
| `priya-sharma` | Priya Sharma | Senior | High-performance data pipelines, fast and opinionated, ships clean code with negative line counts |
| `liam-kowalski` | Liam Kowalski | Senior | Backend, database systems, clever solutions, automates everything, cloud infrastructure |
| `grace-tanaka` | Grace Tanaka | Mid | Exhaustively documented code, thorough |
| `ryan-foster` | Ryan Foster | Mid | Backend development |
| `emma-liu` | Emma Liu | Junior | Learning backend patterns (requires senior coverage) |

**Embedded QA:** Victor Santos

---

### Sarah Kim's Team

**Specialization:** Frontend-heavy, UX-critical, accessibility-sensitive projects.

**Character:** Strong frontend focus with accessibility from day one. Design collaboration is tighter -- Olivia Hart and Sarah share a design-to-engineering vocabulary. Strong cross-functional communication. Sarah translates between design, product, and engineering. Protective of junior developers -- creates conditions where juniors ask questions and flag mistakes early.

| Slug | Name | Level | Strengths |
|------|------|-------|-----------|
| `sarah-kim` | Sarah Kim | Dev Lead | Frontend, UX-engineering, full-stack, team empathy, accessibility advocacy |
| `james-obrien` | James O'Brien | Senior | Accessibility engineering, design system work, methodical and sequential, code written to be read |
| `derek-washington` | Derek Washington | Senior | Frontend, integration work, accessibility gaps, financial tech, non-linear problem-solving |
| `carlos-mendez` | Carlos Mendez | Mid | Frontend development |
| `nina-petrov` | Nina Petrov | Mid | Frontend development |
| `tyler-brooks` | Tyler Brooks | Junior | Learning frontend patterns (requires senior coverage) |

**Embedded QA:** Rachel Kim

---

### Tomas Rivera's Team

**Specialization:** Infrastructure-heavy, performance-critical, systems-level projects.

**Character:** Infrastructure-first approach with performance consciousness. Minimal ceremony -- communicates in short sentences and long silences. Strong operational discipline: runbooks, deployment checklists, postmortem culture. Best incident response capability in the engineering org. Nathan Cross (DevOps) works most closely with this team.

| Slug | Name | Level | Strengths |
|------|------|-------|-----------|
| `tomas-rivera` | Tomas Rivera | Dev Lead | Infrastructure, DevOps-adjacent, systems reliability, calm under fire |
| `aisha-mohammed` | Aisha Mohammed | Senior | Database architecture, infrastructure, careful and precise, rarely wrong |
| `sam-oconnell` | Sam O'Connell | Mid | Infrastructure, systems work |
| `alex-nguyen` | Alex Nguyen | Junior | Learning infrastructure patterns (requires senior coverage) |

**Embedded QA:** Rachel Kim (shared with Sarah's team)

---

## 2. Shared Resources

These individuals are not permanently assigned to a team. They are pulled in based on project needs.

### DevOps

| Slug | Name | Title | Notes |
|------|------|-------|-------|
| `nathan-cross` | Nathan Cross | DevOps Lead | CI/CD pipeline setup, deployment strategy, infrastructure decisions. Works most closely with Tomas's team. Pulled in during scoping for greenfield projects and any project with deployment requirements. |
| `jasmine-wu` | Jasmine Wu | DevOps Engineer | Implements and maintains infrastructure. Reports to Nathan. |

### Security

| Slug | Name | Title | Notes |
|------|------|-------|-------|
| `frank-morrison` | Frank Morrison | Security Lead | Mandatory security reviews on brownfield projects during scoping. Optional on greenfield. Reviews security-tagged tasks. |
| `zoe-adams` | Zoe Adams | Security Analyst | Deeper analysis -- dependency auditing, vulnerability scanning, compliance checking. Pulled in by Frank when needed. |

### Design

| Slug | Name | Title | Notes |
|------|------|-------|-------|
| `olivia-hart` | Olivia Hart | Design Lead | Pulled in during scoping for any project with a user-facing component. Makes design system decisions. Shares a design-to-engineering vocabulary with Sarah Kim. |
| `kai-oduya` | Kai Oduya | UI/UX Designer | UX work delegated by Olivia. |
| `maya-russo` | Maya Russo | Graphic Designer | Visual design work delegated by Olivia. |

---

## 3. Allocation Rules by Project Size

### Small Projects (<10 issues)

| Component | Allocation |
|-----------|-----------|
| Dev Lead | 1 (partial allocation -- 0.3-0.5 capacity) |
| Developers | 1-2 from the lead's team |
| QA | Shared from the lead's embedded QA engineer (partial allocation) |
| PM | 1 (Hannah or Jordan, partial) |
| SA | Daniel Kwon (scoping only, then advisory) |

**Example:** A small API enhancement. Marcus at 0.4, Priya at 1.0, Victor at 0.3. Hannah at 0.2.

### Medium Projects (10-30 issues)

| Component | Allocation |
|-----------|-----------|
| Dev Lead | 1 (significant allocation -- 0.6-0.8 capacity) |
| Developers | 2 seniors + 1-2 mids from the lead's team |
| QA | 1 dedicated QA engineer |
| PM | 1 (Hannah or Jordan, significant allocation) |
| SA | Daniel Kwon (scoping + early delivery oversight) |
| DevOps | Nathan/Jasmine if deployment work is in scope |
| Design | Olivia + Kai/Maya if user-facing |
| Security | Frank if brownfield or security-sensitive |

**Example:** A medium frontend application. Sarah at 0.7, James at 1.0, Derek at 1.0, Nina at 0.8. Rachel at 1.0. Jordan at 0.5. Olivia at 0.3, Kai at 0.5.

### Large Projects (30+ issues)

| Component | Allocation |
|-----------|-----------|
| Dev Leads | 2-3 (one per workstream) |
| Developers | Multiple per workstream, drawn from each lead's team |
| QA | Dedicated QA per workstream |
| PM | 1-2 (may need both Hannah and Jordan for very large) |
| SA | Daniel Kwon (scoping + architecture oversight throughout) |
| TPM | Ben Hartley actively managing cross-stream coordination |
| DevOps | Nathan + Jasmine |
| Design | Full design team if user-facing |
| Security | Frank + Zoe |

**Example:** A large full-stack platform. Marcus leading backend workstream (Priya, Liam, Grace). Sarah leading frontend workstream (James, Derek, Carlos, Nina). Tomas leading infrastructure workstream (Aisha, Sam). Victor on backend QA, Rachel on frontend + infra QA. Both Hannah and Jordan. Nathan + Jasmine on DevOps. Olivia + Kai + Maya on design. Frank + Zoe on security.

---

## 4. Team Selection Logic

Ben matches projects to teams based on technical fit. The primary routing rule:

| Project Characteristic | Primary Team | Rationale |
|----------------------|--------------|-----------|
| Backend-heavy, API-driven | Marcus Chen | Strongest backend fluency, high test standards |
| Data-intensive, data pipeline | Marcus Chen | Priya for high-performance data work |
| Frontend-heavy, UX-critical | Sarah Kim | Frontend focus, accessibility from day one |
| Accessibility-sensitive | Sarah Kim | James O'Brien for accessibility engineering |
| Design-system work | Sarah Kim | Shared vocabulary with Olivia Hart |
| Infrastructure-heavy | Tomas Rivera | Infrastructure-first approach, operational discipline |
| Performance-critical | Tomas Rivera | Performance consciousness, low-level optimization |
| Systems-level, DevOps-adjacent | Tomas Rivera | Nathan Cross works most closely with this team |
| Full-stack (balanced) | Marcus + Sarah | Split workstreams by backend/frontend boundary |
| Platform build (all layers) | All three teams | Workstream per layer, Ben coordinates |

### Tech Stack Matching

| Tech Stack | Routes To |
|------------|-----------|
| Node.js, Python, Go, REST APIs, GraphQL | Marcus |
| React, Vue, Angular, CSS, design systems | Sarah |
| Docker, Kubernetes, Terraform, CI/CD, monitoring | Tomas |
| Database architecture (complex queries, migrations, schemas) | Marcus (with Aisha pulled from Tomas's team) |
| Real-time systems (WebSockets, streaming) | Marcus (backend) + Sarah (frontend) |
| Low-latency, kernel-level performance | Tomas |

### Cross-Team Resource Sharing

Certain individuals can be pulled across team boundaries:

| Person | Home Team | Pulled Into | When |
|--------|-----------|-------------|------|
| Aisha Mohammed | Tomas Rivera | Marcus Chen | Complex database architecture work. Aisha pauses, asks follow-ups, and refuses to estimate until she has read the code. Her pull requests are rarely large but almost never wrong. |
| Nathan Cross | Shared (DevOps) | Tomas Rivera (primary) | Any project, but works most closely with Tomas's team. Always pulled in for greenfield projects. |
| Olivia Hart | Shared (Design) | Sarah Kim (primary) | User-facing projects. Shares design-to-engineering vocabulary with Sarah. |
| Derek Washington | Sarah Kim | Marcus Chen | Integration work with a frontend-facing component. Non-linear thinker who works odd hours. |

---

## 5. Trading Division Integration

**Mandatory rule:** If the project touches financial calculations, market data, trading logic, or blockchain, the Trading Division is pulled in during scoping, not after implementation begins.

### Trading Division Members

| Slug | Name | Title | Pulled In When |
|------|------|-------|---------------|
| `richard-cole` | Richard Cole | Senior Managing Director | All trading projects. Authority over trading-domain technical decisions. |
| `yuki-tanaka` | Yuki Tanaka | Quantitative Analyst | Statistical modeling, backtesting, alpha research |
| `owen-blake` | Owen Blake | Trading Systems Architect | Low-latency systems, market data, execution engines. Collaborates with the assigned dev lead on architecture. |
| `jax-morrison` | Jax Morrison | Crypto/DeFi Specialist | Blockchain, smart contracts, DEX integration, tokenomics |
| `catherine-wright` | Catherine Wright | Risk & Compliance Analyst | Risk modeling, regulatory compliance, audit readiness |
| `victor-reeves` | Victor Reeves | Domain Expert (Former Trader) | Market microstructure, trading workflows, user requirements validation |

### Trading Activation Criteria

The Trading Division is activated when ANY of the following are true:
- Project plan mentions trading, financial markets, or quantitative analysis
- Tech stack includes market data feeds, FIX protocol, or exchange connectivity
- Customer explicitly tags the project as trading-related
- Daniel Kwon identifies trading-domain complexity during discovery

### Integration Model

Trading specialists integrate INTO the assigned engineering team, not alongside it:

```
Standard allocation:
  Marcus (lead) + Priya + Liam + Victor (QA)

With trading integration:
  Marcus (lead) + Priya + Liam + Victor (QA)
  + Owen Blake (trading systems architecture, collaborates with Marcus)
  + Yuki Tanaka (quant validation)
  + Catherine Wright (compliance review)
```

Richard Cole (SMD) has authority over trading-domain technical decisions. If Richard and the dev lead disagree on a trading-related technical question, Richard's position takes priority. For non-trading technical decisions, the dev lead retains authority.

---

## 6. Allocation Constraints

Ben enforces these as hard rules. They are not guidelines.

### Constraint 1: Never split a dev lead across more than 2 projects

Marcus, Sarah, and Tomas each own their team's delivery. Splitting attention further degrades both the lead's effectiveness and the team's trust.

**Check:** Before allocating a lead, verify their current allocation in `registry.json`. If they are already on 2 projects, they cannot be assigned to a third.

### Constraint 2: Junior developers only with senior coverage

Emma Liu, Tyler Brooks, and Alex Nguyen are never assigned to a project without at least one senior developer on the same workstream.

**Check:** Before allocating a junior, verify that a senior from the same team is also allocated to the same project and workstream.

| Junior | Must Have Senior Coverage From |
|--------|-------------------------------|
| Emma Liu | Priya Sharma, Liam Kowalski, or Grace Tanaka (Marcus's team) |
| Tyler Brooks | James O'Brien, Derek Washington (Sarah's team) |
| Alex Nguyen | Aisha Mohammed (Tomas's team) |

### Constraint 3: Match tech stack to team strength

Ben does not assign React-heavy frontend work to Tomas's team, and does not assign kernel-level performance work to Sarah's team. The teams have distinct competencies and Ben respects them.

**Check:** Before allocating, verify that the project's primary tech stack matches the team's specialization (see Section 4).

### Constraint 4: Check current utilization from central registry

Ben checks the rolling 12-week capacity view before committing any team to new work. He has turned down internal requests with a spreadsheet rather than an argument.

**Check:** Read `registry.json` and sum capacity for each proposed team member. If a person's total capacity across all projects would exceed 1.0, they cannot be allocated.

### Constraint 5: Trading division mandatory for financial projects

If the project touches financial calculations, market data, trading logic, or blockchain, the Trading Division is pulled in during scoping. This is mandatory, not optional.

**Check:** If project is tagged `trading` or Daniel flags trading-domain complexity, verify Trading Division members are included in the allocation.

---

## 7. Reading and Updating the Central Registry

### Registry Location

```
$JWARE_HOME/.jware/registry.json
```

### Registry Schema

```json
{
  "activeProjects": [
    {
      "name": "string",
      "path": "string -- absolute path to project root",
      "status": "string -- intake | active | paused | review | completed",
      "phase": "string",
      "teams": [
        {
          "lead": "string -- personality name",
          "workstream": "string"
        }
      ],
      "pm": "string",
      "startDate": "ISO 8601"
    }
  ],
  "teamUtilization": {
    "{slug}": {
      "allocated": true,
      "project": "string -- project name or null",
      "role": "string -- lead | developer | qa | devops | security | design | pm | sa | null",
      "capacity": 0.0
    }
  },
  "updatedAt": "ISO 8601"
}
```

### Reading the Registry

Before any allocation decision, read the full registry to determine:

1. **Who is available?** Any person with `allocated: false` or `capacity < 1.0`.
2. **Who is overloaded?** Any person with `capacity >= 0.8` should be allocated cautiously.
3. **Which leads are available?** Check `marcus-chen`, `sarah-kim`, `tomas-rivera` -- they cannot exceed 2 projects.
4. **Which QA engineers are available?** Victor Santos and Rachel Kim. Rachel can be split across 2 teams.
5. **Are shared resources free?** Check DevOps, Security, Design utilization.

### Updating the Registry

After allocation is decided, update the registry:

1. Add the project to `activeProjects`.
2. For each allocated person, update their `teamUtilization` entry:
   - Set `allocated: true`
   - Set `project` to the project name (or comma-separated names if split)
   - Set `role` to their role on this project
   - Set `capacity` to their allocated fraction (0.0 to 1.0)
3. Set `updatedAt` to current ISO 8601 timestamp.
4. Write using atomic file operations (write to temp, fsync, rename).

### Releasing Resources

When a project completes or a person is removed from a project:

1. Update their `teamUtilization` entry:
   - If they have no remaining allocations: set `allocated: false`, `project: null`, `role: null`, `capacity: 0.0`
   - If they are still on another project: update `project` and `capacity` to reflect remaining allocation
2. If the project is complete, remove it from `activeProjects` (or update its status to `completed`).
3. Update `updatedAt`.

---

## 8. Allocation Algorithm

```
FUNCTION allocateTeam(project, scopeDocument):

  1. READ registry.json for current utilization

  2. DETERMINE project size:
     - Count scoped issues
     - Small: <10 | Medium: 10-30 | Large: 30+

  3. DETERMINE primary team:
     - Read Daniel Kwon's technical assessment from the scope document
     - Match tech stack and project characteristics to team (Section 4)
     - If multiple teams needed (large project), assign workstreams

  4. CHECK lead availability:
     - Selected lead must have capacity (not on 2 projects already)
     - If unavailable, consider the next-best-fit team
     - If no lead available, escalate to Diana Okafor for resource discussion

  5. SELECT team members:
     - Based on project size (Section 3), select from the lead's team
     - Ensure junior coverage constraint (Constraint 2)
     - Check each person's capacity in the registry
     - If a needed person is fully allocated, discuss trade-offs with the lead

  6. ASSIGN QA:
     - Marcus's team: Victor Santos
     - Sarah's team: Rachel Kim
     - Tomas's team: Rachel Kim (shared)
     - Large projects: may need both Victor and Rachel

  7. CHECK cross-team needs:
     - Database complexity? Pull Aisha from Tomas's team
     - Integration with frontend? Pull Derek for frontend-facing components
     - User-facing? Pull Design (Olivia + Kai/Maya)
     - Deployment work? Pull DevOps (Nathan + Jasmine)
     - Brownfield or security-sensitive? Pull Security (Frank, possibly Zoe)

  8. CHECK trading activation:
     - If project matches trading criteria (Section 5), pull Trading Division members
     - Richard Cole (SMD) always included for trading projects
     - Other trading members selected based on specific domain needs

  9. ASSIGN PM:
     - Check Hannah Reeves's active project count
     - If Hannah has <3 active projects: assign Hannah
     - If Hannah is at capacity: assign Jordan Pace
     - Relationship-complex clients get Hannah; operationally demanding clients get Jordan

  10. VALIDATE all constraints (Section 6):
      - No lead on 3+ projects
      - No junior without senior coverage
      - Tech stack matches team
      - No person exceeds 1.0 total capacity
      - Trading division present if required

  11. UPDATE registry.json with all allocations

  12. RETURN allocation record:
      {
        teams: [...],
        pm: "...",
        sa: "Daniel Kwon",
        sharedResources: [...],
        tradingDivision: [...] or null
      }
```

---

## 9. PM Assignment Logic

| Condition | Assigned PM | Rationale |
|-----------|-------------|-----------|
| Hannah has <3 active projects | Hannah Reeves | Default assignment |
| Hannah has 3+ active projects | Jordan Pace | Capacity overflow |
| Relationship-complex client | Hannah Reeves | Hannah surfaces organizational dynamics and remembers things clients said months ago |
| Operationally demanding client | Jordan Pace | Jordan arrives with data, historical velocity, structured tracking |
| Very large project (2+ workstreams) | Both Hannah and Jordan | One for client relationship, one for operational tracking |

Ben Hartley manages both PMs and makes the final PM assignment decision based on client type and current workload.

---

## 10. Capacity Reference

Standard capacity allocations by role:

| Role | Typical Capacity | Rationale |
|------|-----------------|-----------|
| Dev Lead | 0.6 - 0.8 | Also does reviews, meetings, planning, mentoring |
| Senior Developer | 0.8 - 1.0 | Primarily coding, some review duties |
| Mid Developer | 1.0 | Full-time on project work |
| Junior Developer | 1.0 | Full-time, with senior oversight |
| QA Engineer | 0.5 - 1.0 | Can be split across 2 teams (Rachel) |
| PM | 0.2 - 0.5 | Manages communication, not full-time per project |
| SA (Daniel) | 0.2 - 0.4 | Scoping + advisory, not full-time after kickoff |
| TPM (Ben) | 0.1 - 0.2 | Cross-project coordination, not embedded |
| DevOps | 0.2 - 0.5 | Pulled in for specific infrastructure work |
| Security | 0.1 - 0.3 | Reviews during scoping, spot checks during development |
| Design | 0.2 - 0.5 | Front-loaded during scoping and early sprints |
