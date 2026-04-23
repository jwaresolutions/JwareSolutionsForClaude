# Test Quality Rules

> **Loaded when:** Agent is writing or reviewing tests.
> These rules are mandatory constraints, not suggestions.

---

## The 9 Rules

### Rule 1: Assert Something Real
Every test must assert an observable outcome. No `assert True`, no `assert x >= 0` on values that structurally cannot be negative. If the assertion cannot fail when the implementation is wrong, delete it.

### Rule 2: Test Behavior, Not Existence
Do not test that an object can be created, that `isinstance` returns True, or that an attribute exists. Test what the object *does* when you call it with specific inputs.

### Rule 3: Name Tests by What Breaks
`test_order_rejects_negative_quantity` tells you what regressed. `test_order_creation` tells you nothing. The name must describe the broken behavior a failure would reveal.

### Rule 4: Parameterize Same Function, Multiple Inputs
When testing the same function with different inputs, use `@pytest.mark.parametrize` (Python) or `test.each` (JS/TS). Do not copy-paste the same test body with different values.

### Rule 5: One Concept per Test
A test should verify one behavioral concept. If a test fails, you should know exactly what broke without reading the test body. Split tests that assert multiple unrelated behaviors.

### Rule 6: Do Not Test Language Guarantees
Do not write tests that verify:
- A StrEnum member is a valid string
- A dataclass/Pydantic model stores the value you passed to its constructor
- A dict has a key you just set
- Default values on model fields
- Type system properties (isinstance, issubclass)

These are language guarantees. They cannot fail without the language itself being broken.

### Rule 7: Mock at the Boundary, Not the Internals
Mock external dependencies (HTTP clients, databases, file systems, message queues). Never mock private methods, internal state (`obj._handlers`), or the unit under test itself. If you need to reach into internals to make a test work, the design needs to change, not the test.

### Rule 8: Test Edge Cases
Every function must have tests for: boundary values (exactly at limit, one over, one under), error paths (invalid input, missing data, permission denied), and degenerate cases (empty list, zero, None, empty string).

### Rule 9: Delete Worthless Tests
If a test cannot fail when the implementation has a real bug, it provides no value. Delete it. A smaller test suite with meaningful assertions is better than a large suite that creates a false sense of coverage.

---

## Prohibited Patterns

```python
# FALSE-POSITIVE GUARD: hides failures as silent passes
result = get_order(order_id)
if result is not None:       # <-- if this is None, test passes silently
    assert result.status == "filled"

# TAUTOLOGICAL ASSERTION: can never fail
count = len(items)           # len() returns >= 0 by definition
assert count >= 0

# LITERAL NULL TEST
assert True

# LANGUAGE GUARANTEE TEST
assert isinstance(action, RiskAction)   # StrEnum membership
assert order.symbol == "AAPL"           # dataclass passthrough
assert config.timeout == 30             # Pydantic default
```

```typescript
// WEAK DOM ASSERTION: passes even when element is missing from DOM
expect(screen.queryByText("Submit")).toBeTruthy();   // use .toBeInTheDocument()
expect(screen.queryByRole("button")).toBeDefined();  // use .toBeInTheDocument()
```

---

## Few-Shot Examples

### BAD: Tautological assertion with false-positive guard

```python
def test_portfolio_value():
    """This test has two fatal flaws."""
    portfolio = Portfolio()
    portfolio.add_position("AAPL", Decimal("10"), Decimal("150.00"))
    value = portfolio.total_value()
    if value is not None:          # Flaw 1: if total_value() returns None
        assert value >= 0          #   due to a bug, test passes silently
                                   # Flaw 2: portfolio value is always >= 0
                                   #   when positions have positive prices
```

**Why it's bad:** If `total_value()` returns `None` (a real bug), the guard skips the assertion and the test passes. Even when it does run, `>= 0` is tautological for a portfolio with positive prices. This test passes with *any* implementation, correct or broken.

### GOOD: Behavioral assertion with controlled data

```python
def test_portfolio_value_sums_all_positions():
    """Catches bugs in aggregation, price lookup, and quantity handling."""
    portfolio = Portfolio()
    portfolio.add_position("AAPL", quantity=Decimal("10"), price=Decimal("150.00"))
    portfolio.add_position("GOOG", quantity=Decimal("5"), price=Decimal("200.00"))

    value = portfolio.total_value()

    assert value == Decimal("2500.00")  # 10*150 + 5*200
```

**Why it catches real bugs:** If aggregation skips a position, value is wrong. If price lookup fails, value is wrong. If quantity is ignored, value is wrong. The exact expected value is derived from the controlled inputs. Any implementation bug produces a different number.

---

## Mutation Testing Mindset

For every test you write, ask: **"If I introduced a specific bug, would this test catch it?"**

| Bug introduced | Weak assertion (passes) | Strong assertion (catches it) |
|---|---|---|
| Return empty list instead of results | `assert len(r) >= 0` | `assert len(r) == 3` |
| Swap sort order | `assert len(sorted) == len(unsorted)` | `assert sorted == ["A", "B", "C"]` |
| Skip one item in aggregation | `assert total > 0` | `assert total == Decimal("2500.00")` |
| Return None on error | `if r is not None: assert ...` | `assert r is not None` then assert value |

If your test still passes after a mutation, your assertion is too weak. Strengthen it or delete the test.
