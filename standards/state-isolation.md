# State Isolation

> **Loaded when:** Agent is writing or reviewing tests that interact with module-level state, caches, singletons, configuration, or databases.
> Tests that share mutable state produce intermittent failures and order-dependent results.

---

## Rules

### 1. Reset Module-Level State Between Tests
Any module-level mutable state (caches, singletons, global config, registries) must be reset before or after each test. Use `autouse` fixtures for state that many tests touch.

```python
@pytest.fixture(autouse=True)
def reset_calendar_cache():
    """Ensure each test starts with a clean calendar cache."""
    calendar._clear_cache()
    yield
    calendar._clear_cache()
```

### 2. Never Rely on Test Execution Order
Tests must pass when run individually, in any order, and in parallel. If test B only passes after test A runs, test B is broken.

Signs of order dependence:
- Tests pass in suite, fail when run alone
- Tests fail when run in reverse order
- Tests fail under `pytest-randomly`

### 3. Clean Up What You Modify
If a test modifies shared state (database rows, config values, environment variables, singleton instances), it must restore the original state after completion. Use fixtures with teardown, not manual cleanup at the end of the test body.

```python
@pytest.fixture
def override_config():
    original = config.get("max_positions")
    config.set("max_positions", 5)
    yield
    config.set("max_positions", original)
```

### 4. Inject State Through Helper Functions
When testing code that uses module-level state (e.g., a calendar cache), expose helper functions (`_load_cache`, `_clear_cache`) for test injection. Do not patch the module-level variable directly -- it creates brittle tests that break when the implementation changes.

```python
# REQUIRED: use the module's own injection point
calendar._load_cache({"2026-01-01": True, "2026-01-02": False})

# PROHIBITED: patch the variable directly
with patch("jtx.scheduler.calendar._HOLIDAY_CACHE", {"2026-01-01": True}):
    ...
```

### 5. Use MagicMock for Sync Methods, AsyncMock for Async
`AsyncMock` on a synchronous method (e.g., `session.add`) produces "coroutine never awaited" warnings and can cause tests to silently misbehave. Match the mock type to the method signature.

```python
# REQUIRED: sync method gets MagicMock
mock_session = MagicMock()
mock_session.add = MagicMock()       # session.add is synchronous
mock_session.commit = AsyncMock()    # session.commit is async

# PROHIBITED: AsyncMock on sync method
mock_session.add = AsyncMock()       # produces "coroutine never awaited" warning
```

### 6. Isolate Database State
Each test that touches the database must either:
- Use a transaction that rolls back after the test (preferred), or
- Use a dedicated test database that is reset between tests

Never share committed database state between tests.

```python
@pytest.fixture
def db_session():
    """Each test gets a rolled-back transaction."""
    session = SessionLocal()
    session.begin_nested()  # savepoint
    yield session
    session.rollback()
    session.close()
```

### 7. Environment Variables
Tests that modify `os.environ` must restore it. Use `monkeypatch` (pytest) or a fixture -- never set env vars directly without cleanup.

```python
# REQUIRED
def test_api_key_from_env(monkeypatch):
    monkeypatch.setenv("API_KEY", "test-key-123")
    assert config.get_api_key() == "test-key-123"

# PROHIBITED
def test_api_key_from_env():
    os.environ["API_KEY"] = "test-key-123"  # leaks to other tests
    assert config.get_api_key() == "test-key-123"
```

---

## Common State Isolation Failures

| Symptom | Likely Cause | Fix |
|---|---|---|
| Tests pass alone, fail in suite | Shared mutable state not reset | Add autouse fixture to reset state |
| Tests fail randomly | Order-dependent state | Run with `pytest-randomly`, add isolation |
| "Coroutine never awaited" warnings | AsyncMock on sync method | Use MagicMock for sync methods |
| Flaky DB tests | Committed transactions leaking | Use savepoint + rollback pattern |
| Config values wrong in later tests | `os.environ` or config not restored | Use `monkeypatch` or fixture teardown |

---

## Detecting Isolation Problems

Run tests in random order to surface hidden dependencies:

```bash
pip install pytest-randomly
pytest --randomly-seed=12345
```

If any test fails that passes in the default order, you have an isolation problem. Fix the test, not the order.
