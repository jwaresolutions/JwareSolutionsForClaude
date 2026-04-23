# Code Review Checklist

> **Loaded when:** Agent is reviewing code (PR review, code review, quality gate).
> Every checkbox must be evaluated. Unchecked items require explanation.

---

## Test Quality

- [ ] **Tests assert behavior, not existence** -- No `isinstance` checks, no "creation succeeds" tests. Tests verify what the code *does* with specific inputs. *(Rule 2)*
- [ ] **No false-positive guards** -- No `if result is not None:` wrapping assertions. If the result can be None, assert that it is not None explicitly, then assert the value.
- [ ] **No tautological assertions** -- No `assert x >= 0` on values that structurally cannot be negative. No `assert True`. Every assertion must be capable of failing when the implementation is wrong.
- [ ] **No language-guarantee tests** -- No testing that a StrEnum is a StrEnum, that a dataclass stores constructor args, or that Pydantic defaults are applied. *(Rule 6)*
- [ ] **Edge cases covered** -- Boundary values (at limit, one over, one under), error paths (invalid input, missing data), degenerate cases (empty, zero, None). *(Rule 8)*
- [ ] **Test names describe what breaks** -- `test_order_rejects_negative_quantity`, not `test_order` or `test_order_creation`. *(Rule 3)*

## External APIs

- [ ] **Error handling at every call site** -- Every HTTP call has explicit try/except with domain-specific exceptions, not bare except or silent fallbacks.
- [ ] **Response shape validated** -- Code checks that the response contains expected keys/types before accessing them. Not just HTTP status.
- [ ] **Failure surfaced, not swallowed** -- No silent `return []` or `return None` on API failure. Failures are logged and raised or explicitly handled with documented fallback behavior.

## Mocking

- [ ] **Mocks at boundaries, not internals** -- HTTP clients, databases, file systems are mocked. Private methods, internal state (`obj._handlers`), and the unit under test are not. *(Rule 7)*
- [ ] **Mock types match method signatures** -- `MagicMock` for sync methods, `AsyncMock` for async methods. No AsyncMock on `session.add` or similar sync calls.

## Financial Precision

- [ ] **Decimal for money** -- All prices, quantities, P&L, equity, and order values use `Decimal`, not `float`.
- [ ] **Decimal serialized as string** -- JSON responses send Decimal values as `"150.25"`, not `150.25`.
- [ ] **Exact Decimal comparisons in tests** -- No `pytest.approx()` for money. Exact `Decimal` equality.
- [ ] **Boundary tests at penny precision** -- At limit, one cent over, one cent under.

## Module Boundaries

- [ ] **No cross-module internal imports** -- Modules depend on protocols, not implementations. No importing another module's private functions or internal classes.
- [ ] **Import direction follows dependency graph** -- No upward or sideways imports. Core flows down to leaf modules.
- [ ] **Events for cross-cutting notification** -- Modules publish events; they do not call other modules' methods directly.

## State Isolation

- [ ] **Module-level state reset between tests** -- Caches, singletons, config restored via fixtures.
- [ ] **No test order dependence** -- Tests pass individually and in random order.
- [ ] **Environment variables cleaned up** -- `monkeypatch` or fixture teardown, not raw `os.environ` mutation.

## Frontend (when applicable)

- [ ] **`.toBeInTheDocument()` for DOM presence** -- Not `.toBeTruthy()` or `.toBeDefined()`.
- [ ] **`.toHaveTextContent()` for text** -- Not manual `.textContent` access.
- [ ] **Sort/filter tests assert content and order** -- Not just element count.
- [ ] **No tests for stub/placeholder components** -- Document with a comment instead.

## Process

- [ ] **Commit history shows tests before implementation** -- Evidence of TDD where applicable.
- [ ] **Mutation testing mindset applied** -- For each test, reviewer asks: "Would this pass if the implementation had a specific bug?" If yes, the test needs a stronger assertion.

---

## How to Use This Checklist

1. Evaluate every checkbox against the code under review.
2. Mark items as passing, failing, or not applicable.
3. For any failing item, cite the specific file and line.
4. Do not approve code with failing items unless there is an explicit, documented exception.
