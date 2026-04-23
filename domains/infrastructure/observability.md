# Domain: Observability
**Loaded when:** Agent is implementing logging, metrics, alerting, or distributed tracing.
**Key concern:** Signal-to-noise ratio. An alert that fires 50 times a day gets ignored. A log without context is useless for debugging.

---

## Structured Logging

```python
# WRONG: unstructured
logger.info(f"User {user_id} placed order {order_id} for ${amount}")

# RIGHT: structured, queryable
logger.info("order_placed", extra={"user_id": user_id, "order_id": order_id, "amount": str(amount)})
```

| Level | When | Example |
|---|---|---|
| **DEBUG** | Dev-only detail | "Cache miss for key user:42" |
| **INFO** | Normal operations | "Order created", "User logged in" |
| **WARNING** | Degraded but functional | "Retry 2/3 for payment API" |
| **ERROR** | Failed, needs attention | "Payment failed", "DB connection lost" |

Production runs at INFO. Every ERROR must include enough context to diagnose without reproducing.

### Correlation IDs

Generate a `correlation_id` in middleware, propagate via HTTP headers across services. Every log line includes it. Debug a failed request by searching for that ID across all services.

```python
@app.middleware("http")
async def logging_context(request, call_next):
    correlation_id = request.headers.get("X-Correlation-ID", str(uuid4()))
    with structlog.contextvars.bind_contextvars(correlation_id=correlation_id, path=request.url.path):
        return await call_next(request)
```

## Metrics

| Type | Measures | Example |
|---|---|---|
| **Counter** | Cumulative (only up) | `http_requests_total` |
| **Gauge** | Current value (up/down) | `active_connections` |
| **Histogram** | Distribution | `request_duration_seconds` |

### Four Golden Signals (Google SRE)

| Signal | Alert when |
|---|---|
| **Latency** | p99 > 2x baseline |
| **Traffic** | Sudden drop > 50% |
| **Errors** | Error rate > 1% |
| **Saturation** | CPU/memory/disk > 80% |

**Label cardinality must be bounded.** Never use user IDs, emails, or free-text as label values.

## Alerting

Alert on symptoms (error rate, latency), not causes (CPU). Include `for` duration to avoid transient spikes. Link every alert to a runbook.

```yaml
- alert: HighErrorRate
  expr: rate(http_errors_total[5m]) / rate(http_requests_total[5m]) > 0.01
  for: 5m
  annotations:
    runbook: "https://wiki.example.com/runbooks/high-error-rate"
```

### SLI/SLO-Based Alerting

Define SLIs (e.g., % requests < 500ms), set SLOs (99.5% over 30 days), alert when error budget burn rate will exhaust budget within 1 hour.

## Never Log

Passwords, tokens, API keys, credit cards, SSNs, PII, connection strings with credentials. Scrub sensitive headers before logging.

## Common Pitfalls

| Pitfall | Why it breaks | Fix |
|---|---|---|
| Logging PII/secrets | Compliance violation | Scrub before logging |
| Unbounded label cardinality | Metrics storage explodes | Labels from bounded sets only |
| Alert fatigue | Real alerts ignored | Alert on symptoms, severity tiers |
| No correlation ID | Can't trace across services | Generate and propagate in middleware |
| ERROR without context | Can't diagnose | Include request ID, user ID, inputs |
| DEBUG in production | Storage costs spike | INFO minimum in production |
| No runbook in alert | Paged engineer wastes time | Every alert links to runbook |
