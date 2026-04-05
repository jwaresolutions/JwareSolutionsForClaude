# JWare Solutions — Virtual IT Company

JWare Solutions is a 48-person event-driven virtual software company that builds bespoke software applications. It operates as a real company with personalities, processes, meetings, disagreements, and resolution — all backed by persistent file-based state.

## Setup

```bash
/plugin marketplace add https://github.com/justinmalone/JwareSolutions
/plugin install jware-solutions
```

`JWARE_HOME` is set automatically to the plugin install directory. All paths reference `$JWARE_HOME`.

## Quick Start

From any project directory:
- **Just type** — any message goes to Daniel + PM (default channel, always active)
- `/jware` — Submit a new project for intake
- `/jware-auto` — Run Jane (orchestration AI). Use `/jware-auto 1 cycle` for a single cycle.
- `/jware-auto N cycles` — Run exactly N cycles
- `/jware-status [1|2|3]` — Check progress (read-only)
- `/jware-meeting [with Name]` — Request a meeting with your contacts
- From the JwareSolutions directory: `/jware-dashboard [1|2|3]` — Monitor all projects

## How It Works

1. **You bring a plan** to any project directory and invoke `/jware`
2. **Daniel Kwon (Solutions Architect) + a PM** conduct an intake meeting with you
3. **The company scopes, allocates teams, and begins development**
4. **Real Claude agents** write real code with personality-driven behavior
5. **Code reviews, QA, meetings, and escalations** happen between personalities
6. **You make decisions** via the `.jware/issues` approve/reject/defer system
7. **You monitor progress** at visibility level 1 (outcomes), 2 (key decisions), or 3 (full internal process)

## Architecture

```
skills/              — Invocable skills (/jware, /jware-auto, etc.)
engine/              — Reusable logic modules (personality loader, event processor, etc.)
personalities/       — 48 personality profiles organized by department
templates/           — State file templates for new projects
docs/architecture/   — System design, event engine, and company process specs
.jware/registry.json — Central registry of all active projects
```

## Key Paths

| Resource | Path |
|----------|------|
| Personalities | `$JWARE_HOME/personalities/` |
| Skills | `$JWARE_HOME/skills/` |
| Engine Modules | `$JWARE_HOME/engine/` |
| Templates | `$JWARE_HOME/templates/` |
| Central Registry | `$JWARE_HOME/.jware/registry.json` |
| Issue Operations | `$JWARE_HOME/engine/issue-reference.md` |
| Issue Schema | `$JWARE_HOME/engine/issue-schema.md` |
| Issue CLI Script | `$JWARE_HOME/scripts/jware-issue.sh` |

## Customer Point of Contact

Your contacts are ALWAYS:
- **Daniel Kwon** — Solutions Architect (technical truth)
- **Hannah Reeves** or **Jordan Pace** — Project Manager (relationship + process)

No other JWare employee initiates direct communication with you unless you request them in a meeting.

## Decision Interface

The `.jware/issues` is the decision interface:
- JWare creates issues labeled `decision-needed` when they need your input
- Individual developers add their notes and perspective to issues
- You discuss issues with Daniel + PM via `/jware-meeting`
- You approve/reject/defer on the issue itself
- Your verdicts trigger the company to act

## Visibility Levels

| Level | What You See |
|-------|-------------|
| 1 | Outcomes only — task counts, completion %, blockers, decisions needed |
| 2 | Key decisions — who debated what, why they chose X over Y, review outcomes |
| 3 | Full internal process — meeting transcripts, code review dialogue, personality-driven debates |

Set per project at intake. Change anytime with `/jware-status [level]`.

## Multi-Session Support

You can run multiple sessions simultaneously:
- **Session 1**: `/jware-auto` — the company works
- **Session 2**: You review issues, have meetings, make decisions
- **Session 3**: `/jware-status 3` — watch the full process

All state is file-based (`.jware/` and `.jware/issues/`), so sessions see each other's changes.

## Company Roster (48 people)

### C-Suite
- Elena Vasquez (CEO), Raj Patel (CTO), Diana Okafor (COO)

### Engineering — Dev Leads
- Marcus Chen (Team 1 — backend), Sarah Kim (Team 2 — frontend), Tomas Rivera (Team 3 — infrastructure)

### Engineering — Senior Devs
- Priya Sharma, James O'Brien, Aisha Mohammed, Liam Kowalski, Derek Washington

### Engineering — Mid Devs
- Nina Petrov, Ryan Foster, Sam O'Connell, Grace Tanaka, Carlos Mendez

### Engineering — Junior Devs
- Emma Liu, Tyler Brooks, Alex Nguyen

### QA
- Margaret Chen (Lead), Victor Santos, Rachel Kim

### DevOps
- Nathan Cross (Lead), Jasmine Wu

### Security
- Frank Morrison (Lead), Zoe Adams

### Design
- Olivia Hart (Lead), Kai Oduya, Maya Russo

### Project Management
- Ben Hartley (TPM), Hannah Reeves (PM), Jordan Pace (PM)

### Solutions Architecture
- Daniel Kwon

### Sales & BD
- Patricia Walsh, Marcus Johnson

### Marketing & PR
- Claire Bennett, Ethan Cole

### Support
- Kevin Shaw (Lead), Lisa Tran

### Operations
- Sandra Mitchell (HR), Tony Martinez (Admin), Helen Park (Controller)

### Trading Division
- Richard Cole (SMD), Yuki Tanaka (Quant), Owen Blake (Trading Systems), Jax Morrison (Crypto/DeFi), Catherine Wright (Risk/Compliance), Victor Reeves (Domain Expert)
