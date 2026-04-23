# Team Charlie — Infrastructure

**Lead:** Tomas Rivera
**Specialty:** Infrastructure, DevOps, performance, API routes, integration testing

## Core Standards (always loaded for Charlie dispatches)
- $JWARE_HOME/standards/test-quality-rules.md
- $JWARE_HOME/standards/external-api-handling.md
- $JWARE_HOME/standards/state-isolation.md
- $JWARE_HOME/standards/module-boundary-rules.md

## Domain Triggers

When assigning a task, scan the acceptance criteria and affected files for domain keywords. Load the matching domain modules and consult the listed SMEs BEFORE dispatching the developer.

| If task involves... | Load domains | Consult SME |
|---------------------|-------------|-------------|
| risk route, risk API, risk endpoint | financial/risk-compliance.md, financial/financial-precision.md | catherine-wright |
| PDT route, PDT endpoint | financial/pdt-rules.md | catherine-wright, victor-reeves |
| strategy route, strategy endpoint | financial/trading-systems.md | owen-blake |
| backtest, sweep, parameter grid | financial/trading-systems.md | yuki-tanaka |
| deploy, pipeline, Docker, Terraform | infrastructure/cicd-pipelines.md, infrastructure/docker-containerization.md | nathan-cross |
| Terraform, IaC, cloud | infrastructure/terraform-iac.md | nathan-cross |
| monitoring, alerts, health check, metrics | infrastructure/observability.md | nathan-cross |
| database, migration, query performance | infrastructure/database-design.md | — |
| API route, endpoint, FastAPI | web-backend/python-fastapi.md, application/rest-api-design.md | — |
| WebSocket, broadcast, connection mgmt | application/websockets-realtime.md | — |
| auth, JWT, Cloudflare Access, middleware | application/auth-security.md | frank-morrison |
| external API, Alpaca, Polygon, Massive, Finnhub, FRED | standards/external-api-handling.md | — |
| security, vulnerability, penetration | application/auth-security.md | frank-morrison, zoe-adams |
| benchmark, performance, latency | infrastructure/observability.md | — |

## SME Consultation Protocol

When a domain trigger matches:
1. Load the SME's personality (conversational template — full personality for the consultation)
2. Present the task summary and specific domain questions
3. Capture the SME's guidance as structured notes
4. Include those notes in the developer's task prompt under "## Domain Guidance"
5. The developer receives the domain module + the SME's specific guidance for this task

If no SME is listed, the domain module alone is sufficient.

## Default Tech Context

Unless the project specifies otherwise, Charlie works with:
- Python 3.12+, FastAPI, pytest
- Integration tests with real (in-memory) databases where possible
- mypy (strict), ruff
- Docker for containerization
- Module-level state requires autouse fixtures for isolation
- Benchmarks use tracemalloc for memory, time.perf_counter for wall clock
