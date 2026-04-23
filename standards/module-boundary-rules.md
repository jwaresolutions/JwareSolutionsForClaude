# Module Boundary Rules

> **Loaded when:** Agent is writing or reviewing code that involves cross-module communication, imports, or integration tests.
> Module isolation is the foundation of maintainable architecture.

---

## Rules

### 1. Modules Communicate Through Events and Protocols Only
Modules do not call each other's functions directly. All cross-module communication happens through:
- **Event bus**: For asynchronous, decoupled notifications (order filled, position changed, risk limit hit)
- **Protocol interfaces**: For synchronous contracts (a module depends on a protocol, not an implementation)

```python
# REQUIRED: depend on the protocol
from jtx.core.protocols import RiskManager

class OrderExecutor:
    def __init__(self, risk: RiskManager):  # protocol, not implementation
        self._risk = risk

# PROHIBITED: depend on the implementation
from jtx.risk.engine import RiskEngine  # direct import of another module's internals

class OrderExecutor:
    def __init__(self, risk: RiskEngine):
        self._risk = risk
```

### 2. No Internal Imports Across Modules
A module's internal files, helper functions, private classes, and implementation details are off-limits to other modules. Only the public interface (defined in protocols) is importable.

```python
# PROHIBITED
from jtx.broker.alpaca_client import AlpacaSession  # internal implementation
from jtx.risk.engine import _calculate_exposure       # private function
from jtx.strategy.signals import SignalBuffer          # internal data structure

# REQUIRED
from jtx.core.protocols import BrokerClient, RiskManager, StrategyEngine
```

### 3. Public Interfaces Live in Protocol Files
All interfaces that cross module boundaries must be defined as protocols in the core protocol file (e.g., `jtx.core.protocols`). If a function or class is used by another module, it must have a corresponding protocol definition.

### 4. Import Direction Follows the Dependency Graph
Imports must flow in one direction only, following the declared module dependency graph. No upward imports (importing from a module that depends on you) or sideways imports (importing from a peer module at the same level).

```
core --> broker, data, risk --> strategy, portfolio, sizing --> backtest, orchestrator --> monitor, api
```

Arrows indicate allowed import direction. `strategy` can import from `core` but not from `backtest`. `broker` can import from `core` but not from `strategy`.

### 5. Event Bus for Cross-Cutting Concerns
When a module needs to notify other modules of state changes, use the event bus. The publishing module must not know or care who subscribes.

```python
# REQUIRED: publish event, don't call subscribers directly
event_bus.publish(OrderFilled(order_id=order.id, fill_price=fill.price))

# PROHIBITED: module directly notifies another module
portfolio_manager.update_position(order.id, fill.price)
risk_engine.recalculate(order.id)
```

### 6. Mock at the Protocol Boundary in Tests
When testing a module that depends on another module, mock the protocol interface, not the other module's internals.

```python
# REQUIRED: mock the protocol
mock_risk = MagicMock(spec=RiskManager)
mock_risk.check_order.return_value = RiskDecision(allowed=True)
executor = OrderExecutor(risk=mock_risk)

# PROHIBITED: patch the other module's internals
with patch("jtx.risk.engine.RiskEngine._check_exposure"):
    ...
```

---

## Detecting Violations

### Import Violations
Search for cross-module imports that bypass protocols:

```bash
# Find imports from other modules' internals (not core)
rg "from jtx\.(broker|risk|strategy|portfolio|sizing|backtest|orchestrator|monitor|api)\." src/jtx/ --glob '!src/jtx/core/'
```

Any match that imports something other than the module's top-level public API is a violation.

### Dependency Direction Violations
If module A imports from module B, verify that B is below A in the dependency graph. If B depends on A (directly or transitively), this is a circular dependency and must be broken by introducing an event or protocol.

---

## Adding a New Cross-Module Interface

1. Define the protocol in `jtx.core.protocols`
2. Implement the protocol in the owning module
3. Consumers depend on the protocol, never the implementation
4. Register the implementation via dependency injection or configuration
5. Add integration tests that verify the protocol contract with the real implementation
