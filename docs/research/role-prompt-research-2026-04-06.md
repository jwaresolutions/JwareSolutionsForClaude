# Role Prompt Research — 2026-04-06

Research compiled for JWare role prompt rewrite planning.

---

## 1. Multi-Agent Framework Role Definitions

### CrewAI
Three core fields: role, goal, backstory. 25+ optional config params including tool scoping, delegation permissions, iteration limits, separate templates for system/input/response.
- Source: https://docs.crewai.com/en/concepts/agents

### MetaGPT
Five roles producing structured output documents (PRDs, architecture diagrams, interface definitions, task graphs). Encodes SOPs into prompts. Agents receive documents, not chat.
- Source: https://arxiv.org/abs/2308.00352
- Source: https://github.com/FoundationAgents/MetaGPT

### ChatDev
Inception prompting: each phase starts with role/goal/constraint reinforcement to prevent drift.
- Source: https://github.com/OpenBMB/ChatDev

### AutoGen (Microsoft)
Dynamic prompt templating (Jinja-style). Named roles with system prompts. ReAct patterns.
- Source: https://developer.microsoft.com/blog/designing-multi-agent-intelligence

### Anthropic Agent Creation Template
Six steps: core intent, expert persona, comprehensive instructions (boundaries, methodologies, edge cases, output format), performance optimization (decision frameworks, quality control, escalation), identifier, triggers.
- Source: https://github.com/anthropics/claude-code/blob/main/plugins/plugin-dev/skills/agent-development/references/agent-creation-system-prompt.md

---

## 2. The Persona Problem: Expert Roles Can Hurt Code Quality

### PRISM Study (USC, March 2026)
Generic expert personas ("You are a senior software engineer") reduced coding accuracy from 71.6% to 68.0%. Personas activate instruction-following mode at expense of factual retrieval. Fix: use specific behavioral constraints instead of identity claims.
- Source: https://arxiv.org/abs/2603.18507

### PromptHub Meta-Analysis
Simple role labels provide minimal or negative benefit. Detailed behavioral specifications are what change output quality.
- Source: https://www.prompthub.us/blog/role-prompting-does-adding-personas-to-your-prompts-really-make-a-difference

---

## 3. AI-Generated Test Quality Problems

### Test Oracle Problem (ASE 2025)
LLMs achieve <50% accuracy on test assertions. Core failure: assert actual behavior (including bugs) rather than expected behavior.
- Source: https://www.lucadigrazia.com/papers/ase2025.pdf
- Source: https://goodenoughtesting.com/articles/llms-test-generation-research-insights

### Specific Antipatterns
1. Tautological assertions
2. Implementation coupling / test mirroring
3. State machine blindness
4. Over-mocking (AI uses mocks 95% vs humans 57% fakes, 51% spies)
- Source: https://arxiv.org/html/2602.00409v1
- Source: https://super-productivity.com/blog/ai-generated-tests-guide/

### Prevention Strategies
1. Mutation testing mindset: "Would this test still pass if the implementation had a specific bug?"
2. Specification-first: write test names as behavioral specs before assertions
3. Two-step workflow: identify testable aspects first, then write assertions
4. Review every assertion asking "what bug would this miss?"
5. Prefer real dependencies over mocks for interaction testing
- Source: https://arxiv.org/html/2412.14841v1

---

## 4. Seniority Differentiation (IC1-IC6 Framework)

| Dimension | Junior | Mid | Senior |
|-----------|--------|-----|--------|
| Decision autonomy | Implement within parameters. Ask when ambiguous. | Convert ambiguity into plans. Independent implementation decisions. | Architectural tradeoffs. Only escalate cross-module. |
| Scope | Single file/function | Single feature, multiple files | Multi-service, contributes patterns |
| Error handling | Handle specified cases. Ask about unknowns. | Identify unspecified edge cases. Document assumptions. | Design for failure modes not yet encountered. |
| Outputs | Tests, implementation, summary | + assumptions, clarifications | + ADR, tradeoff analysis, risk assessment |

- Source: https://sprad.io/resources/software-engineer-skill-matrix-competency-framework-by-level-ic1-ic6-behaviors-examples-template-3914c

---

## 5. Engineering Standards in Agent Prompts

### O'Reilly Agent Spec Guide
Three-tier boundaries: Always do / Ask first / Never do.
- Source: https://www.oreilly.com/radar/how-to-write-a-good-spec-for-ai-agents/

### Agentic Coding Handbook (Tweag)
Treat each prompt like a task for a junior developer: detailed but focused. Explain "why" for better architectural decisions.
- Source: https://tweag.github.io/agentic-coding-handbook/PROMPT_ENGINEERING/

### HumanLayer (CLAUDE.md Best Practices)
~150-200 reliable instructions. Under 300 lines. Progressive disclosure via separate files.
- Source: https://www.humanlayer.dev/blog/writing-a-good-claude-md

### Awesome Reviewers
30+ system prompts for agentic code review distilled from real PRs.
- Source: https://github.com/baz-scm/awesome-reviewers

### CrashOverride
Concrete examples dramatically outperform abstract instructions. Five elements: persona (specific, not generic), context, examples, instructions, output format.
- Source: https://crashoverride.com/blog/prompting-llm-security-reviews
