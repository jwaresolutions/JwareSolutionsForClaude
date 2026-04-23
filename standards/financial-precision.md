# Financial Precision

> **Loaded when:** Agent is writing or reviewing code that handles money, prices, quantities, or financial calculations.
> Floating-point arithmetic is not acceptable for financial values.

---

## Rules

### 1. Decimal for All Money Values
Use `Decimal` (Python) or equivalent exact-precision type for every value that represents money or a financial quantity. This includes: prices, position sizes, P&L, equity, order values, fees, commissions, margin, and account balances.

```python
# REQUIRED
from decimal import Decimal
price = Decimal("150.25")
quantity = Decimal("100")
value = price * quantity  # Decimal("15025.00")

# PROHIBITED
price = 150.25
quantity = 100
value = price * quantity  # 15025.000000000002 (floating point)
```

### 2. Serialize Decimal as String in JSON
When sending Decimal values over JSON (API responses, stored configs, messages), serialize as string. JSON has no decimal type; `float` conversion introduces precision loss.

```python
# REQUIRED
{"price": "150.25", "quantity": "100", "value": "15025.00"}

# PROHIBITED
{"price": 150.25, "quantity": 100, "value": 15025.0}
```

### 3. Use Exact Comparisons in Tests
When testing financial calculations, compare exact Decimal values. Do not use `pytest.approx()` or threshold comparisons for money. If the result is not exact, the calculation is wrong.

```python
# REQUIRED
assert portfolio.total_equity() == Decimal("50000.00")

# PROHIBITED
assert float(portfolio.total_equity()) == pytest.approx(50000.0, rel=1e-6)
```

### 4. Test Boundary Values Precisely
For every threshold, limit, or boundary in financial logic, write tests for exactly three cases:

| Case | Example (max position $10,000) |
|---|---|
| Exactly at limit | `Decimal("10000.00")` |
| One cent under | `Decimal("9999.99")` |
| One cent over | `Decimal("10000.01")` |

```python
@pytest.mark.parametrize("size,expected", [
    (Decimal("9999.99"), True),    # under limit: allowed
    (Decimal("10000.00"), True),   # at limit: allowed (inclusive)
    (Decimal("10000.01"), False),  # over limit: rejected
])
def test_position_size_limit(size, expected):
    assert risk.is_position_allowed(size) == expected
```

### 5. Document Boundary Semantics
Every threshold must document whether it is inclusive (`>=`, `<=`) or exclusive (`>`, `<`). Ambiguity in boundary semantics causes off-by-one-cent bugs.

```python
# REQUIRED: document the semantics
MAX_POSITION_SIZE = Decimal("10000.00")  # inclusive: positions <= this value are allowed
```

### 6. Currency Formatting Is Display Only
Formatting values with currency symbols, commas, and fixed decimal places is a presentation concern. Store and compute with raw Decimal values. Format only at the display/serialization boundary.

```python
# Computation layer
equity = Decimal("1234567.89")

# Display layer (only here)
formatted = f"${equity:,.2f}"  # "$1,234,567.89"
```

### 7. Construct Decimals from Strings
Always construct Decimal from string literals, never from float literals. `Decimal(0.1)` captures the float imprecision; `Decimal("0.1")` is exact.

```python
# REQUIRED
threshold = Decimal("0.1")

# PROHIBITED - captures float imprecision
threshold = Decimal(0.1)  # Decimal('0.1000000000000000055511151231257827021181583404541015625')
```

---

## Common Violations

| Violation | Fix |
|---|---|
| `float(price) * float(qty)` | `Decimal(price) * Decimal(qty)` |
| `json.dumps({"price": float(d)})` | `json.dumps({"price": str(d)})` |
| `assert total == pytest.approx(100.0)` | `assert total == Decimal("100.00")` |
| `Decimal(0.01)` | `Decimal("0.01")` |
| `round(value, 2)` on float | Use `Decimal.quantize()` for rounding |
| `if equity > 0:` (float comparison) | Use Decimal comparison throughout |

---

## Rounding

When rounding is required (e.g., for order sizes that must be whole shares), use `Decimal.quantize()` with explicit rounding mode. Document the rounding direction.

```python
from decimal import ROUND_DOWN
shares = (equity / price).quantize(Decimal("1"), rounding=ROUND_DOWN)
# ROUND_DOWN: never buy more shares than we can afford
```
