# Domain: Pattern Day Trader (PDT) Rules
**Loaded when:** Agent is implementing or modifying PDT detection, day trade counting, or the rolling window calculation.
**Key concern:** The rolling window uses 5 trading days (not calendar days), computed from a market calendar that excludes weekends and holidays.

---

## Regulatory Background

FINRA Rule 4210: A pattern day trader is someone who executes 4 or more day trades within 5 business days, if day trades represent more than 6% of total trades. Accounts flagged as PDT must maintain $25,000 minimum equity.

This system enforces PDT proactively: block the 4th day trade before it happens, rather than flagging after the fact.

## Key Definitions

| Term | Definition |
|---|---|
| **Day trade** | A buy and sell (or sell and buy) of the same security in the same trading day |
| **Rolling window** | 5 trading days ending today (inclusive) |
| **Trading day** | A day when the stock market is open (excludes weekends, NYSE holidays) |
| **Equity threshold** | $25,000 (configurable buffer, e.g., $25,500 for safety margin) |

## Rolling Window Calculation

The window is 5 **trading days**, not 5 calendar days. A Friday-to-Friday span may contain only 5 trading days, but a span crossing a holiday week may require 8+ calendar days to cover 5 trading days.

```python
# WRONG: calendar days
window_start = today - timedelta(days=5)

# RIGHT: trading days from market calendar
trading_days = calendar.get_trading_days(end=today, count=5)
window_start = trading_days[0]
```

### The 5-Trading-Day Property

The rolling window must always contain exactly 5 trading days. This is a testable invariant:

```python
def test_rolling_window_always_contains_5_trading_days(calendar):
    """Verify the window property regardless of holidays."""
    for test_date in [date(2026, 1, 5), date(2026, 7, 6), date(2026, 11, 30)]:
        window = calendar.get_rolling_window(test_date, count=5)
        trading_days_in_window = calendar.count_trading_days(window.start, window.end)
        assert trading_days_in_window == 5
```

## Day Trade Detection

A day trade is a buy+sell (or sell+buy) of the same symbol on the same trading day. Cross-day round trips are not day trades.

## Equity Threshold

If account equity >= $25,000, PDT does not apply. Use a configurable buffer (e.g., $500) above the threshold for safety margin near the boundary.

### Exit Exemption

PDT must never block an exit order. A trader must always be able to close a position to reduce risk, even when the day trade limit is reached.

```python
def test_pdt_allows_exit_when_limit_reached():
    """4th day trade that closes an existing position must be allowed."""
    ctx = RiskContext(day_trades_in_window=3, is_exit=True, equity=Decimal("20000"))
    result = pdt_rule.evaluate(order, ctx)
    assert result.action == RiskAction.ALLOW
```

## Crypto Exemption

PDT is a FINRA rule that applies only to securities (stocks, options). Crypto is not a security under FINRA. PDT must never apply to crypto trades.

```python
def test_pdt_never_applies_to_crypto():
    ctx = RiskContext(
        day_trades_in_window=10,  # way over limit
        equity=Decimal("1000"),   # way under threshold
        asset_type=AssetType.CRYPTO,
    )
    result = pdt_rule.evaluate(order, ctx)
    assert result.action == RiskAction.ALLOW
```

Additionally, crypto markets are always open, so the concept of "trading day" does not apply. The `is_always_open` check must bypass calendar-based window calculations entirely.

## Testing Rules

### Use Fixed Dates

Never use `date.today()` in PDT tests. Tests must be deterministic and reproducible regardless of when they run.

```python
# WRONG: flaky depending on day of week, holidays
window = get_rolling_window(date.today())

# RIGHT: fixed date with known calendar
window = get_rolling_window(date(2026, 3, 15))  # Known to be a Tuesday
```

### Required Test Cases

| Scenario | Expected |
|---|---|
| 0-3 day trades in window, under threshold | ALLOW |
| 4th day trade, under threshold | HALT_TRADING |
| 4th day trade, over threshold | ALLOW (exempt) |
| 4th day trade, under threshold, is exit | ALLOW (exit exempt) |
| Any number of day trades, crypto | ALLOW (crypto exempt) |
| Window spanning a holiday | Correct 5-trading-day count |
| Weekend: window lookback skips Sat/Sun | Correct trading day boundaries |

## Common Pitfalls

| Pitfall | Why it breaks | Fix |
|---|---|---|
| `date.today()` in tests | Non-deterministic, fails on weekends/holidays | Use fixed dates |
| Calendar days instead of trading days | Wrong window size, missed/extra trades counted | Use market calendar |
| Blocking exit orders | Trader trapped in losing position | Always check exit exemption |
| Applying PDT to crypto | Regulatory mismatch, unnecessary blocking | Check asset type first |
| Hardcoded $25K without buffer | Slippage near boundary causes unexpected blocks | Make buffer configurable |
| Not testing holiday-spanning windows | Off-by-one in window boundaries | Test dates around known holidays |
