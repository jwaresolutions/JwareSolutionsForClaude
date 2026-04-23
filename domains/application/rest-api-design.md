# Domain: REST API Design
**Loaded when:** Agent is designing, implementing, or reviewing REST API endpoints.
**Key concern:** Response shape contracts must be pinned in tests -- field names, types, and serialization format. A 200 with the wrong body is still a bug.

---

## Endpoint Conventions

```
GET    /api/{resource}           # List (with pagination)
GET    /api/{resource}/{id}      # Get single
POST   /api/{resource}           # Create
PUT    /api/{resource}/{id}      # Full update
PATCH  /api/{resource}/{id}      # Partial update
DELETE /api/{resource}/{id}      # Delete
```

Plural nouns for resources: `/api/orders`, not `/api/order`. Nest sub-resources one level deep max.

### HTTP Status Codes

| Code | When | Response body |
|---|---|---|
| 200 | Successful GET, PUT, PATCH | Resource or collection |
| 201 | Successful POST (created) | Created resource + `Location` header |
| 204 | Successful DELETE | No body |
| 400 | Malformed request | Error object |
| 404 | Resource not found | Error object |
| 422 | Validation error | Error object with field-level details |
| 500 | Unhandled server error | Error object (no stack traces in production) |

### Error Response Format

```json
{ "detail": "Position not found for symbol FAKE", "code": "POSITION_NOT_FOUND" }
```

Validation errors include field-level details: `{"detail": "Validation failed", "code": "VALIDATION_ERROR", "errors": [{"field": "quantity", "message": "Must be positive"}]}`.

## Pagination

Use `limit`/`offset` query parameters. Response includes total count:

```json
{ "items": [...], "total": 156, "limit": 20, "offset": 40 }
```

Default `limit`: 20. Maximum `limit`: 100. Always enforce a maximum to prevent full-table dumps.

## Filtering and Sorting

Filters as query params: `GET /api/orders?status=FILLED&symbol=AAPL`. Sort with optional `-` prefix for descending: `GET /api/orders?sort=-created_at`.

## Serialization Rules

| Type | Serialize as | Example |
|---|---|---|
| Decimal | String (never JSON number) | `"150.25"` |
| DateTime | ISO 8601 with timezone | `"2026-04-06T14:30:00Z"` |
| Enum | String value | `"BUY"`, `"FILLED"` |

## Testing API Contracts

### Pin Response Shape

Status code alone is insufficient. Assert field names, types, and serialization format.

```python
def test_get_position_response_shape():
    response = client.get("/api/positions/AAPL")
    assert response.status_code == 200
    data = response.json()
    assert data["symbol"] == "AAPL"
    assert isinstance(data["quantity"], str)       # Decimal as string
    assert isinstance(data["average_price"], str)  # Decimal as string
```

### Pin Error Shape

```python
def test_missing_position_error_shape():
    response = client.get("/api/positions/FAKE")
    assert response.status_code == 404
    assert "detail" in response.json()
```

### Test Pagination

```python
def test_pagination_no_overlap():
    page1 = client.get("/api/orders?limit=5&offset=0").json()
    page2 = client.get("/api/orders?limit=5&offset=5").json()
    ids1 = {o["id"] for o in page1["items"]}
    ids2 = {o["id"] for o in page2["items"]}
    assert ids1.isdisjoint(ids2)
```

### Test Serialization

```python
def test_decimal_serialized_as_string():
    data = client.get("/api/positions/AAPL").json()
    assert isinstance(data["quantity"], str)

def test_datetime_is_iso8601():
    data = client.get("/api/orders/123").json()
    datetime.fromisoformat(data["created_at"])  # Raises if invalid
```

## Common Pitfalls

| Pitfall | Why it breaks | Fix |
|---|---|---|
| Testing only status codes | Wrong body shape passes silently | Pin field names and types in assertions |
| Decimal as JSON number | Precision loss for financial values | Serialize as string |
| No pagination limit cap | Client can dump entire table | Enforce maximum limit (100) |
| Inconsistent error format | Client cannot parse errors reliably | Use standard `{detail, code}` structure |
| Missing `Location` header on 201 | Client cannot find created resource | Return header with resource URL |
| Dates without timezone | Ambiguous timestamps | Always use ISO 8601 with `Z` or offset |
