# Domain: Python FastAPI
**Loaded when:** Agent is implementing or modifying FastAPI route handlers, middleware, or API endpoints.
**Key concern:** Module-level state in route files creates test isolation failures. Use dependency injection for all shared state.

---

## Architecture Patterns

### Route Organization

Routes are organized by domain module. Each router is a `APIRouter` instance mounted on the main app.

```python
# src/jtx/api/routes/portfolio.py
from fastapi import APIRouter, Depends

router = APIRouter(prefix="/api/portfolio", tags=["portfolio"])

@router.get("/positions")
async def get_positions(service: PortfolioService = Depends(get_portfolio_service)):
    return await service.get_all_positions()
```

### Dependency Injection

Use `Depends()` for everything that holds state: database sessions, services, configuration, authentication. Never instantiate services at module level -- module-level state is shared across requests and tests, causing isolation failures. Override dependencies in tests with `app.dependency_overrides[get_service] = lambda: mock_service`.

### Pydantic v2 for Validation

Use Pydantic models for all request/response shapes. Use `model_validator(mode="after")` for cross-field validation. Add `model_config = ConfigDict(json_encoders={Decimal: str})` for Decimal serialization.

### Error Responses

Use `HTTPException` with specific status codes and actionable detail messages. Standard codes:

| Code | When |
|---|---|
| 200 | Successful GET, PUT, PATCH |
| 201 | Successful POST that creates a resource |
| 400 | Malformed request (missing fields, wrong types) |
| 404 | Resource not found |
| 422 | Validation error (Pydantic catches these automatically) |
| 500 | Unhandled server error |

## Testing Patterns

### Use TestClient + Mock at Service Boundary

Use `TestClient(app)` for all route tests. Mock the service layer via `app.dependency_overrides`, not the route handler itself. This exercises the full HTTP pipeline: serialization, validation, error handling.

### Pin Response Shapes

Assert field names, types, and serialization format -- not just status codes. Verify Decimal fields are serialized as strings, not floats. Test error paths with specific status codes and detail messages.

## Common Pitfalls

| Pitfall | Why it breaks | Fix |
|---|---|---|
| Module-level service instances | State leaks between tests | Use `Depends()` injection |
| `return service.get()` without `await` | Returns coroutine object, not result | Always `await` async service calls |
| Testing status code only | Wrong response body passes silently | Assert response shape and field values |
| Mocking route handlers | Skips validation, serialization, middleware | Mock at service/dependency boundary |
| Missing `model_config` for Decimal | Decimal serialized as float in JSON | Add `json_encoders={Decimal: str}` |
| Catching `Exception` in routes | Hides bugs as 500 errors | Catch specific exceptions, let others propagate |
