# Domain: iOS (Swift + SwiftUI)
**Loaded when:** Agent is building or modifying an iOS application with SwiftUI.
**Key concern:** Memory management. Retain cycles between closures and objects cause silent memory leaks that grow until the app is killed.

---

## Architecture

Data flows one direction: **Action -> Observable -> State -> View**

| Layer | Responsibility | Key pattern |
|---|---|---|
| **View** | Renders state declaratively | `@State`, `@Binding`, `@Environment` |
| **ViewModel** | Holds UI state, handles logic | `@Observable` (iOS 17+) or `ObservableObject` |
| **Service** | Business logic, coordination | Protocol-based, injected via `@Environment` |
| **Data** | Network, persistence | async/await, SwiftData/Core Data |

## State Management

| Wrapper | Use when |
|---|---|
| `@State` | View-local state (toggle, text field) |
| `@Binding` | Child reads AND writes parent's state |
| `@Environment` | Injecting dependencies down the tree |
| `@Observable` (17+) | ViewModel -- auto-tracks property access |
| `@StateObject` (pre-17) | View creates and owns the ViewModel |
| `@ObservedObject` (pre-17) | ViewModel passed from parent |

### iOS 17+

```swift
@Observable class OrdersViewModel {
    var orders: [Order] = []
    var isLoading = false
    func loadOrders() async {
        isLoading = true
        defer { isLoading = false }
        orders = (try? await orderService.fetchOrders()) ?? []
    }
}

struct OrdersView: View {
    @State private var viewModel = OrdersViewModel()
    var body: some View {
        List(viewModel.orders) { order in OrderRow(order: order) }
        .task { await viewModel.loadOrders() }
    }
}
```

`@Observable` re-renders only when accessed properties change. No `@Published` needed.

## Async/Await

Use `.task` modifier in views (auto-cancelled when view disappears). UI updates must happen on MainActor.

```swift
@MainActor @Observable
class OrdersViewModel {
    // All property updates automatically on main thread
}
```

## Memory Management (ARC)

```swift
// WRONG: retain cycle
onComplete = { self.processResult() }

// RIGHT: weak capture
onComplete = { [weak self] in self?.processResult() }
```

**Rule:** Closures stored as properties or passed to long-lived objects must capture `self` weakly. Exceptions: `.task` modifier, non-escaping closures (`map`, `filter`), short-lived `Task {}`.

## Persistence (SwiftData, iOS 17+)

```swift
@Model class Order {
    var id: UUID
    var status: String
    var amount: Decimal
}
// Query in views:
@Query(sort: \Order.createdAt, order: .reverse) var orders: [Order]
```

Pre-17: Core Data with `NSPersistentContainer`, wrapped in a repository abstraction.

## Testing

| What | Framework | Approach |
|---|---|---|
| ViewModel | XCTest | `async` test methods, verify state |
| Views | ViewInspector / Snapshot | Hierarchy or pixel verification |
| Navigation | XCUITest | End-to-end flows |
| Network | URLProtocol mock | Intercept, return controlled responses |

## App Store

Privacy nutrition labels required. No private APIs. Support current + previous iOS version.

## Common Pitfalls

| Pitfall | Why it breaks | Fix |
|---|---|---|
| Force unwrapping (`!`) | Runtime crash on nil | `if let`, `guard let`, `??` |
| Retain cycle in closure | Memory leak | `[weak self]` in stored/escaping closures |
| UI update off main thread | Undefined behavior | `@MainActor` on ViewModel |
| `@ObservedObject` vs `@StateObject` | ViewModel recreated on parent redraw | `@StateObject` when view owns VM |
| Not testing async ViewModel | Bugs found only at runtime | `async` test methods |
| Ignoring App Store review | Rejection delays release | Read guidelines before building |
