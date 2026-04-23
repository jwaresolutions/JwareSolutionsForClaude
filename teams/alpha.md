# Team Alpha — Backend

**Lead:** Marcus Chen
**Specialty:** Backend services, APIs, data layer, business logic

## Core Standards (always loaded for Alpha dispatches)
- $JWARE_HOME/standards/test-quality-rules.md
- $JWARE_HOME/standards/external-api-handling.md
- $JWARE_HOME/standards/module-boundary-rules.md
- $JWARE_HOME/standards/state-isolation.md

## Domain Triggers

When assigning a task, scan the acceptance criteria and affected files for domain keywords. Load the matching domain modules and consult the listed SMEs BEFORE dispatching the developer.

| If task involves... | Load domains | Consult SME |
|---------------------|-------------|-------------|
| risk rules, risk profiles, halt, daily loss | financial/risk-compliance.md, financial/financial-precision.md | catherine-wright |
| strategy, signal, crossover, momentum, RSI | financial/trading-systems.md | owen-blake |
| PDT, day trade, rolling window, equity threshold | financial/pdt-rules.md, financial/risk-compliance.md | catherine-wright, victor-reeves |
| crypto, BTC, always-open, CoinGecko | financial/crypto-markets.md | jax-morrison |
| deploy, pipeline, rollback, Docker | infrastructure/cicd-pipelines.md, infrastructure/docker-containerization.md | nathan-cross |
| database, migration, SQLAlchemy, Alembic | web-backend/sqlalchemy.md, infrastructure/database-design.md | — |
| FastAPI, endpoint, route, middleware | web-backend/python-fastapi.md | — |
| REST, API design, pagination, serialization | application/rest-api-design.md | — |
| WebSocket, realtime, broadcast | application/websockets-realtime.md | — |
| auth, JWT, token, key management, secrets | application/auth-security.md | frank-morrison |
| external API, Alpaca, Polygon, Massive, Finnhub | standards/external-api-handling.md | — |

## SME Consultation Protocol

When a domain trigger matches:
1. Load the SME's personality (conversational template — full personality for the consultation)
2. Present the task summary and specific domain questions
3. Capture the SME's guidance as structured notes
4. Include those notes in the developer's task prompt under "## Domain Guidance"
5. The developer receives the domain module + the SME's specific guidance for this task

If no SME is listed, the domain module alone is sufficient.

## Default Tech Context

Unless the project specifies otherwise, Alpha works with:
- Python 3.12+, FastAPI, SQLAlchemy 2.0, Alembic
- pytest, mypy (strict), ruff
- uv for dependency management
- Async patterns throughout
