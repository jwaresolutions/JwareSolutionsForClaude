# Domain: Risk & Compliance
**Loaded when:** Agent is implementing or modifying risk rules, the risk evaluation chain, or halt-state behavior.
**Key concern:** The three-layer priority chain (PDT > Risk > Strategy) must never be violated. Risk rules block; strategies cannot override.

---

## The Priority Chain

Risk evaluation follows a strict override hierarchy. Higher layers override lower layers unconditionally.

| Priority | Layer | Examples | Can be overridden by |
|---|---|---|---|
| 1 (highest) | **Regulatory (PDT)** | Pattern Day Trader, wash sale | Nothing |
| 2 | **Risk rules** | Max position size, max drawdown, daily loss limit | Regulatory only |
| 3 (lowest) | **Strategy** | Entry signals, exit signals | Risk and Regulatory |

A strategy signal that passes the strategy layer can still be blocked by a risk rule. A risk rule that permits an order can still be blocked by PDT. The chain short-circuits on first failure: once any layer blocks, evaluation stops.

## Risk Rule Evaluation

### Short-Circuit Behavior

```python
# Conceptual evaluation order
for rule in [pdt_rule, max_drawdown_rule, max_position_rule, daily_loss_rule]:
    result = rule.evaluate(order, context)
    if result.action != RiskAction.ALLOW:
        return result  # Short-circuit: do not evaluate remaining rules
return RiskResult(action=RiskAction.ALLOW)
```

### Every Rule: Both Directions

Every risk rule must be tested in both the block and permit directions. A rule that only tests blocking may have a bug that blocks everything. A rule that only tests permitting may have a bug that permits everything.

```python
def test_max_drawdown_blocks_when_exceeded():
    context = RiskContext(current_drawdown=Decimal("0.11"))  # 11%
    result = rule.evaluate(order, context)
    assert result.action == RiskAction.HALT_TRADING

def test_max_drawdown_permits_when_within_limit():
    context = RiskContext(current_drawdown=Decimal("0.05"))  # 5%
    result = rule.evaluate(order, context)
    assert result.action == RiskAction.ALLOW
```

### Boundary Semantics

Every threshold must document and test its boundary behavior: is `>=` the trigger or `>`?

```python
# Rule: halt if drawdown >= 10%
@pytest.mark.parametrize("drawdown,expected_action", [
    (Decimal("0.09"),  RiskAction.ALLOW),          # under: permit
    (Decimal("0.10"),  RiskAction.HALT_TRADING),    # at boundary: block (inclusive)
    (Decimal("0.11"),  RiskAction.HALT_TRADING),    # over: block
])
def test_drawdown_boundary(drawdown, expected_action):
    result = rule.evaluate(order, RiskContext(current_drawdown=drawdown))
    assert result.action == expected_action
```

## Halt State: Exit-Only Mode

When trading is halted (by PDT, drawdown, or manual override), the system enters exit-only mode. This means:

- New entries are blocked
- Existing position exits are allowed (the trader must be able to reduce risk)
- The halt reason must be surfaced to the user

```python
def test_halt_blocks_new_entry():
    ctx = RiskContext(halted=True, has_position=False)
    result = rule.evaluate(entry_order, ctx)
    assert result.action == RiskAction.HALT_TRADING

def test_halt_allows_exit():
    ctx = RiskContext(halted=True, has_position=True)
    result = rule.evaluate(exit_order, ctx)
    assert result.action == RiskAction.ALLOW
```

## RiskAction Severity

The `RiskAction` enum has escalating severity:

| Action | Meaning | Blocks order? | Affects future orders? |
|---|---|---|---|
| `ALLOW` | Order is permitted | No | No |
| `ALERT` | Order permitted, but notify user | No | No |
| `STRATEGY_EXIT` | Force close the position | Yes (replaces with exit) | No |
| `FORCE_LIQUIDATE` | Immediately close all positions | Yes | Yes (until resolved) |
| `HALT_TRADING` | Stop all trading | Yes | Yes (until manual resume) |

## Testing the Override Chain

The most critical test is verifying that the priority chain holds. This requires integration-style tests that run all three layers together.

```python
def test_pdt_overrides_risk_permit():
    """Even when risk rules say ALLOW, PDT can still block."""
    # Risk rules would permit this order
    # But PDT says no (4th day trade in 5 days, under $25K)
    result = evaluate_full_chain(order, context)
    assert result.action == RiskAction.HALT_TRADING
    assert "PDT" in result.reason
```

## Common Pitfalls

| Pitfall | Why it breaks | Fix |
|---|---|---|
| Testing rules in isolation only | Override chain bugs are invisible | Add integration tests for the full chain |
| Ambiguous boundary semantics | Off-by-one-cent blocking errors | Document `>=` vs `>` on every threshold |
| Halt state blocks exits | Trader cannot reduce risk | Always check exit exemption in halt |
| Testing only the block path | Rule may incorrectly block everything | Test both block AND permit for every rule |
| Ignoring RiskAction severity | Wrong escalation behavior | Test that HALT > FORCE_LIQUIDATE > ALERT |
