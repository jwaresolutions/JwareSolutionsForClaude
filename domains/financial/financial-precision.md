# Domain: Financial Precision
**Loaded when:** Agent is writing or reviewing code that handles money, prices, quantities, or financial calculations.
**Key concern:** A single float-to-Decimal conversion error can cause real money loss. Precision is not a style preference; it is a correctness requirement.

---

## Why This Matters in Trading

Financial precision errors compound. A `0.01` cent rounding error per trade across 10,000 trades per day is $100/day of invisible drift. In a trading system:

- **Position sizing**: Float imprecision in lot calculation means buying more or fewer shares than intended
- **P&L tracking**: Accumulated float errors make reported P&L diverge from actual P&L
- **Risk thresholds**: A $24,999.999999 equity value may pass a `>= 25000` check as float but fail as Decimal
- **Reconciliation**: Broker-reported values (always precise) will not match system values if floats are used

## Rules

### 1. Decimal for All Money Values

Use `Decimal` for every value that represents money or a financial quantity: prices, position sizes, P&L, equity, order values, fees, commissions, margin, account balances.

```python
from decimal import Decimal
price = Decimal("150.25")
quantity = Decimal("100")
value = price * quantity  # Decimal("15025.00") -- exact

# PROHIBITED
price = 150.25
value = price * 100  # 15025.000000000002 -- imprecise
```

### 2. Construct from Strings, Never Floats

`Decimal(0.1)` captures the float's imprecision. `Decimal("0.1")` is exact.

```python
# RIGHT
threshold = Decimal("0.1")

# WRONG -- 56-digit approximation of 0.1
threshold = Decimal(0.1)
# Decimal('0.1000000000000000055511151231257827021181583404541015625')
```

### 3. Serialize as String in JSON

JSON has no decimal type. Serializing as a number converts to float. Pydantic models must set `model_config = ConfigDict(json_encoders={Decimal: str})`.

### 4. Exact Comparisons in Tests

When testing financial calculations, compare exact Decimal values. `pytest.approx()` is for scientific computing, not financial computing.

```python
# RIGHT
assert portfolio.equity == Decimal("50000.00")

# WRONG -- masks precision bugs
assert float(portfolio.equity) == pytest.approx(50000.0, rel=1e-6)
```

### 5. Boundary Tests at Penny Precision

For every financial threshold, test exactly at the boundary, one cent under, and one cent over.

```python
@pytest.mark.parametrize("equity,pdt_applies", [
    (Decimal("24999.99"), True),   # under threshold
    (Decimal("25000.00"), False),  # at threshold (inclusive)
    (Decimal("25000.01"), False),  # over threshold
])
def test_pdt_equity_threshold(equity, pdt_applies): ...
```

### 6. Rounding with Explicit Mode

When rounding is required (e.g., whole shares), use `Decimal.quantize()` with an explicit rounding mode. Document the rounding direction and why.

```python
from decimal import ROUND_DOWN
# ROUND_DOWN: never buy more shares than we can afford
shares = (equity / price).quantize(Decimal("1"), rounding=ROUND_DOWN)
```

### 7. Currency Formatting Is Display Only

Store and compute with raw Decimal. Format with currency symbols and commas only at the display/serialization boundary.

## Common Violations

| Violation | Fix |
|---|---|
| `float(price) * float(qty)` | `Decimal(price) * Decimal(qty)` |
| `json.dumps({"price": float(d)})` | `json.dumps({"price": str(d)})` |
| `assert total == pytest.approx(100.0)` | `assert total == Decimal("100.00")` |
| `Decimal(0.01)` | `Decimal("0.01")` |
| `round(value, 2)` on float | `value.quantize(Decimal("0.01"))` |
| `if equity > 25000:` (int comparison) | `if equity > Decimal("25000.00"):` |
