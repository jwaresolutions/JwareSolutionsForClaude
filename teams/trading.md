# Team Trading — Trading Division

**Lead:** Richard Cole (Senior Managing Director)
**Specialty:** Quantitative analysis, trading systems, crypto, risk/compliance

## Core Standards (always loaded for Trading dispatches)
- $JWARE_HOME/standards/test-quality-rules.md
- $JWARE_HOME/standards/external-api-handling.md
- $JWARE_HOME/standards/financial-precision.md
- $JWARE_HOME/standards/module-boundary-rules.md

## Domain Triggers

Trading division tasks almost always involve financial domains. Load broadly.

| If task involves... | Load domains | Consult SME |
|---------------------|-------------|-------------|
| strategy, signal, crossover, momentum, RSI, VWAP | financial/trading-systems.md | owen-blake, yuki-tanaka |
| risk, halt, daily loss, drawdown, position limit | financial/risk-compliance.md | catherine-wright |
| PDT, day trade, rolling window, regulatory | financial/pdt-rules.md | catherine-wright, victor-reeves |
| crypto, BTC, ETH, DeFi, always-open | financial/crypto-markets.md | jax-morrison |
| backtest, sweep, parameter optimization | financial/trading-systems.md | yuki-tanaka |
| order execution, fill, partial fill, slippage | financial/trading-systems.md, financial/financial-precision.md | owen-blake |
| Alpaca, broker, order submission | standards/external-api-handling.md | owen-blake |
| deploy, pipeline | infrastructure/cicd-pipelines.md | nathan-cross |
| security, key management | application/auth-security.md | frank-morrison |

## SME Consultation Protocol

When a domain trigger matches:
1. Load the SME's personality (conversational template — full personality for the consultation)
2. Present the task summary and specific domain questions
3. Capture the SME's guidance as structured notes
4. Include those notes in the developer's task prompt under "## Domain Guidance"
5. The developer receives the domain module + the SME's specific guidance for this task

## Compliance Review Requirement

Tasks touching risk rules, PDT, or order execution MUST include a compliance review by Catherine Wright (jware-reviewer + catherine-wright) in addition to the standard code review. This is not optional.

## Default Tech Context

- Python 3.12+, Decimal for ALL money
- Event-driven architecture (event bus for cross-module communication)
- Protocol contracts in jtx.core.protocols
- Strategy state documentation required for all strategy changes
- Prefer jware-dev-senior for trading work — complexity and financial risk warrant senior-level analysis
