# Domain: Crypto Markets
**Loaded when:** Agent is implementing or modifying code that handles cryptocurrency trading, data providers, or market-hours logic.
**Key concern:** Crypto markets are always open. Every market-hours guard in the system must have a crypto bypass path, or crypto trading breaks.

---

## How Crypto Differs from Equities

| Property | Equities (Stocks) | Crypto |
|---|---|---|
| Market hours | NYSE: 9:30 AM - 4:00 PM ET | 24/7/365 |
| Holidays | NYSE holiday calendar | None |
| PDT rules | Yes (FINRA) | No (not a security) |
| Symbol format | `AAPL`, `GOOG` | `BTC/USD`, `ETH/USD` |
| Data providers | Alpaca, Polygon | CoinGecko, exchange APIs |
| Fee structure | Per-share or commission-free | Percentage-based (maker/taker) |
| Settlement | T+1 (stocks), T+0 (options) | Near-instant |
| Minimum order | 1 share (fractional varies) | Often very small fractions |

## The `is_always_open` Guard

Every code path that checks market hours must handle the always-open case. The pattern is:

```python
if asset_info.is_always_open:
    # Crypto: skip market-hours check, always tradeable
    return True

# Equity path: check NYSE calendar
return calendar.is_market_open(now)
```

### Where This Guard Must Exist

- **Order submission**: Do not reject crypto orders outside NYSE hours
- **Instance state**: Do not set `WAITING_MARKET_OPEN` for crypto instances
- **Data polling**: Crypto data feeds run 24/7, do not pause on weekends
- **PDT evaluation**: Skip PDT entirely for crypto (see below)
- **Scheduler**: Do not schedule crypto tasks around market open/close

## Symbol Format

Crypto symbols contain a `/` separator: `BTC/USD`, `ETH/USDT`, `SOL/USD`. This affects:

- String matching and parsing (cannot assume symbols are alphanumeric)
- URL encoding (slash must be encoded in API paths)
- Database storage (ensure column width accommodates the format)

```python
# WRONG: assumes alphanumeric symbols
assert symbol.isalpha()

# RIGHT: handle both formats
def is_crypto_symbol(symbol: str) -> bool:
    return "/" in symbol
```

## PDT Exemption

PDT is a FINRA rule for securities only. Crypto is not a security. PDT checks must return `ALLOW` immediately for crypto assets. This is not optional -- applying PDT to crypto incorrectly blocks legitimate trades.

## Data Providers

Crypto uses different data sources (CoinGecko, exchange APIs) than equities (Alpaca, Polygon). Provider selection must branch on asset type.

## Fee Structures

Crypto fees are percentage-based (maker/taker model), not per-share. Fee calculations must branch on asset type -- applying equity fee logic to crypto produces wrong P&L.

## Testing Requirements

| Scenario | What to verify |
|---|---|
| Crypto order outside NYSE hours | Order accepted (not rejected) |
| Crypto instance state | Never enters `WAITING_MARKET_OPEN` |
| PDT with crypto asset | Always returns ALLOW |
| Crypto symbol parsing | Handles `/` separator correctly |
| Data fetch for crypto | Routes to correct provider |
| Fee calculation for crypto | Uses percentage model, not per-share |

## Common Pitfalls

| Pitfall | Why it breaks | Fix |
|---|---|---|
| No `is_always_open` check | Crypto orders rejected on weekends | Add guard before every market-hours check |
| Forgetting crypto in new features | Feature works for stocks, breaks for crypto | Add crypto test case for every market-aware feature |
| Assuming symbols are alphanumeric | Parsing/routing breaks on `BTC/USD` | Handle `/` in symbol format |
| Using NYSE calendar for crypto | Wrong trading day counts, wrong windows | Skip calendar logic for always-open assets |
| Applying equity fees to crypto | Wrong P&L calculation | Branch fee logic on asset type |
