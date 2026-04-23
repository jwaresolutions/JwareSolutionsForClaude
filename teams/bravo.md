# Team Bravo — Frontend

**Lead:** Sarah Kim
**Specialty:** Frontend UI, UX, accessibility, client-side logic

## Core Standards (always loaded for Bravo dispatches)
- $JWARE_HOME/standards/test-quality-rules.md
- $JWARE_HOME/standards/frontend-assertions.md
- $JWARE_HOME/standards/state-isolation.md

## Domain Triggers

When assigning a task, scan the acceptance criteria and affected files for domain keywords. Load the matching domain modules and consult the listed SMEs BEFORE dispatching the developer.

| If task involves... | Load domains | Consult SME |
|---------------------|-------------|-------------|
| chart, graph, equity curve, candlestick | financial/financial-precision.md | owen-blake |
| risk display, halt indicator, loss display | financial/risk-compliance.md, financial/financial-precision.md | catherine-wright |
| market hours, trading clock, NYSE status | financial/trading-systems.md | — |
| price display, PnL, portfolio value | financial/financial-precision.md | — |
| deploy, pipeline, Cloudflare, build | infrastructure/cicd-pipelines.md | nathan-cross |
| API consumption, fetch, backend endpoint | application/rest-api-design.md, standards/external-api-handling.md | — |
| WebSocket, realtime updates, live data | application/websockets-realtime.md | — |
| auth, login, session, token | application/auth-security.md | frank-morrison |
| accessibility, ARIA, screen reader | — | olivia-hart, kai-oduya |
| design, layout, responsive, mobile | — | olivia-hart |

## SME Consultation Protocol

When a domain trigger matches:
1. Load the SME's personality (conversational template — full personality for the consultation)
2. Present the task summary and specific domain questions
3. Capture the SME's guidance as structured notes
4. Include those notes in the developer's task prompt under "## Domain Guidance"
5. The developer receives the domain module + the SME's specific guidance for this task

If no SME is listed, the domain module alone is sufficient.

## Default Tech Context

Unless the project specifies otherwise, Bravo works with:
- Next.js (App Router, static export), React 18+, TypeScript (strict)
- Tailwind CSS for styling
- vitest + @testing-library/react for testing
- .toBeInTheDocument() as the standard DOM assertion (eslint-plugin-jest-dom enforced)
- NEXT_PUBLIC_ env vars are baked at build time — must rebuild after changes
