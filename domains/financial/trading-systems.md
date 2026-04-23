# Domain: Trading Systems
**Loaded when:** Agent is implementing or modifying strategy logic, signal generation, or trading state machines.
**Key concern:** Strategies are stateless signal generators. State lives in the runner, not the strategy.

---

## Core Architecture

A trading system has three layers:

| Layer | Responsibility | Owns state? |
|---|---|---|
| **Strategy** | Receives bars, emits signals | No |
| **Runner / Orchestrator** | Manages position state, routes signals to broker | Yes |
| **Broker** | Executes orders, reports fills | Yes (external) |

Strategies must be pure functions of their input data. They receive market bars and emit `Signal` objects. They do not know whether they are in a position, do not hold references to the broker, and do not manage their own lifecycle.

## Signal Generation Rules

### Signals Fire Once at Transition

A signal must fire exactly once when the condition transitions from false to true. It must NOT fire on every subsequent bar where the condition remains true.

```python
# WRONG: fires every bar above the moving average
def on_bar(self, bar: Bar) -> Signal | None:
    if bar.close > self.moving_average:
        return Signal(side=Side.BUY, ...)

# RIGHT: fires only on the crossover bar
def on_bar(self, bar: Bar) -> Signal | None:
    crossed_above = self.prev_close <= self.moving_average and bar.close > self.moving_average
    if crossed_above:
        return Signal(side=Side.BUY, ...)
```

### Warm-Up Period

Strategies that use indicators (moving averages, RSI, etc.) need N bars of history before signals are valid. During warm-up, the strategy must return `None`, not a potentially invalid signal.

```python
def on_bar(self, bar: Bar) -> Signal | None:
    self._bars.append(bar)
    if len(self._bars) < self.warmup_period:
        return None  # Not enough data yet
    # ... signal logic here
```

### The "No Signal" Case

Most bars produce no signal. This is the dominant code path and must be tested explicitly.

```python
def test_no_signal_when_flat(strategy, flat_market_bars):
    """Most bars should produce None -- test the common case."""
    signals = [strategy.on_bar(bar) for bar in flat_market_bars]
    assert all(s is None for s in signals)
```

## State Transitions

Every strategy must document its states and valid transitions. Use a state diagram or transition table.

```
IDLE -> LONG_SIGNAL (crossover above)
IDLE -> SHORT_SIGNAL (crossover below)
LONG_SIGNAL -> IDLE (crossover below or stop hit)
SHORT_SIGNAL -> IDLE (crossover above or stop hit)
```

Test at the transition level, not the signal level. The question is not "did a signal fire?" but "did the state machine transition correctly given this sequence of bars?"

## Testing Patterns

### Control Input Data

Signal generation is deterministic only when input data is controlled. Use synthetic bars with known values, not random or live data.

```python
def make_bars(closes: list[Decimal]) -> list[Bar]:
    """Create bars with controlled close prices for signal testing."""
    return [Bar(close=c, open=c, high=c, low=c, ...) for c in closes]
```

### Test the Full Lifecycle

```python
def test_strategy_enter_and_exit():
    bars = make_bars([
        *[Decimal("100")] * 20,   # warm-up: flat
        Decimal("105"),            # crossover: should signal BUY
        *[Decimal("106")] * 5,    # holding: no signal
        Decimal("99"),             # crossover back: should signal SELL
    ])
    signals = [strategy.on_bar(b) for b in bars]
    buy_signals = [s for s in signals if s and s.side == Side.BUY]
    sell_signals = [s for s in signals if s and s.side == Side.SELL]
    assert len(buy_signals) == 1
    assert len(sell_signals) == 1
```

## Common Pitfalls

| Pitfall | Why it breaks | Fix |
|---|---|---|
| Strategy holds position state | Couples strategy to runner, breaks backtesting | Move state to runner |
| Signal fires every bar above MA | Generates duplicate orders | Track previous state, fire only on transition |
| No warm-up guard | Invalid signals from insufficient data | Check bar count before signal logic |
| Testing with random data | Non-reproducible failures | Use synthetic bars with known values |
| Skipping "no signal" test | Most common path untested | Explicitly test flat/sideways markets |
| Testing signal existence, not transition | Misses duplicate-signal bugs | Assert signal count across a full bar sequence |
