# External API Handling

> **Loaded when:** Agent is writing or reviewing code that calls external HTTP APIs.
> Every external call is an untrusted boundary. Treat it accordingly.

---

## Rules

### 1. Error Handling at Every Call Site
Every HTTP call must have explicit error handling. Do not let exceptions propagate silently to a generic handler. The call site knows what the request was for and can produce the most useful error message.

```python
# REQUIRED pattern
try:
    resp = await client.get(url, timeout=10.0)
    resp.raise_for_status()
except httpx.TimeoutException:
    raise CalendarAPIError(f"Timeout fetching calendar data from {url}")
except httpx.HTTPStatusError as e:
    raise CalendarAPIError(f"Calendar API returned {e.response.status_code}: {e.response.text[:200]}")
```

### 2. Validate Response Shape Before Use
Do not assume a 200 response contains the shape you expect. APIs change, return partial data, or wrap results differently than documented. Validate before accessing nested fields.

```python
data = resp.json()
if not isinstance(data, list):
    raise CalendarAPIError(f"Expected list of holidays, got {type(data).__name__}")
```

### 3. Raise Specific, Actionable Errors
Error messages must include: what was expected, what was received, and enough context to debug without reproducing. Use domain-specific exception classes, not bare `ValueError` or `RuntimeError`.

```python
# BAD
raise ValueError("bad response")

# GOOD
raise CalendarAPIError(
    f"Expected 'holidays' key in response, got keys: {list(data.keys())}"
)
```

### 4. Never Silently Return Defaults
When an API call fails, the caller must know it failed. Do not catch exceptions and return `[]`, `{}`, `None`, or cached stale data without logging and surfacing the failure. Silent defaults create bugs that are invisible until production.

```python
# PROHIBITED
try:
    holidays = fetch_holidays(year)
except Exception:
    holidays = []  # Silently hides the failure

# REQUIRED
try:
    holidays = fetch_holidays(year)
except CalendarAPIError:
    logger.error("Holiday fetch failed for %d, using cached data", year)
    holidays = cache.get(year)
    if holidays is None:
        raise  # No cache fallback available, surface the failure
```

### 5. Mock at the HTTP Boundary
In tests, mock the HTTP client (httpx, requests, fetch), not internal parsing or business logic. The test should exercise the full code path from HTTP response to returned domain object.

```python
# GOOD: mock the transport layer
respx.get("https://api.example.com/holidays").mock(
    return_value=httpx.Response(200, json=[{"date": "2026-01-01", "name": "New Year"}])
)

# BAD: mock an internal method
with patch.object(CalendarService, "_parse_holidays", return_value=[...]):
    ...
```

### 6. Use Real Captured Responses for Mock Data
When available, mock data should come from real API responses stored in `.api-captures/` or test fixtures. Do not invent JSON structures from memory. APIs have quirks (extra fields, unusual nesting, inconsistent types) that invented data misses.

---

## Required Test Cases for Every External API Call

| Scenario | What to assert |
|---|---|
| **Happy path** | Correct domain objects returned, correct field mapping |
| **Non-200 status** (400, 401, 403, 500, 503) | Specific exception raised with status code in message |
| **Malformed response** (missing keys, wrong types, HTML instead of JSON) | Specific exception raised, not KeyError/TypeError |
| **Timeout** | Specific exception raised, not generic connection error |
| **Partial/empty data** (empty list, null fields, truncated response) | Handled gracefully or raises clear error |

```python
@pytest.mark.parametrize("status_code", [400, 401, 403, 500, 503])
def test_api_error_status_codes(status_code):
    respx.get(URL).mock(return_value=httpx.Response(status_code, text="error"))
    with pytest.raises(CalendarAPIError, match=str(status_code)):
        service.fetch_holidays(2026)

def test_malformed_response_raises():
    respx.get(URL).mock(return_value=httpx.Response(200, text="<html>not json</html>"))
    with pytest.raises(CalendarAPIError, match="Expected"):
        service.fetch_holidays(2026)

def test_timeout_raises():
    respx.get(URL).mock(side_effect=httpx.TimeoutException("timed out"))
    with pytest.raises(CalendarAPIError, match="Timeout"):
        service.fetch_holidays(2026)
```

---

## Timeout Policy

All external HTTP calls must specify an explicit timeout. Never rely on client defaults (which may be infinite). Recommended: 10s for APIs, 30s for large data fetches. Document the choice.
