# Domain: Android (Kotlin + Jetpack Compose)
**Loaded when:** Agent is building or modifying Android application code, Compose UI, or ViewModel logic.
**Key concern:** Lifecycle management. Android destroys and recreates activities on configuration changes. State not in a ViewModel or persistent store will be lost.

---

## Architecture

Single-activity, Compose-first. Data flows one direction: **Event -> ViewModel -> State -> UI**

| Layer | Responsibility | Key class |
|---|---|---|
| **UI** | Renders state, sends events | `@Composable` functions |
| **ViewModel** | Holds UI state, processes events | `ViewModel` + `StateFlow` |
| **Repository** | Coordinates data sources | Interface-backed, injected via Hilt |
| **Data source** | Network (Retrofit), local (Room) | Suspend functions |

## Compose State

`remember` survives recomposition but NOT configuration changes (rotation). Use `rememberSaveable` or ViewModel for durable state.

```kotlin
class OrdersViewModel @Inject constructor(private val repo: OrderRepository) : ViewModel() {
    private val _uiState = MutableStateFlow(OrdersUiState())
    val uiState: StateFlow<OrdersUiState> = _uiState.asStateFlow()

    fun loadOrders() {
        viewModelScope.launch {
            _uiState.update { it.copy(loading = true) }
            val orders = repo.getOrders()
            _uiState.update { it.copy(loading = false, orders = orders) }
        }
    }
}

@Composable
fun OrdersScreen(viewModel: OrdersViewModel = hiltViewModel()) {
    val uiState by viewModel.uiState.collectAsState()
}
```

**Rules:** ViewModel exposes `StateFlow` (never Mutable). UI collects with `collectAsState()`. UI sends events via ViewModel methods only.

### Side Effects

| API | When |
|---|---|
| `LaunchedEffect(key)` | Suspend function when key changes |
| `DisposableEffect(key)` | Setup + cleanup (listeners) |
| `rememberCoroutineScope()` | Launch coroutines from callbacks |

## Coroutines

```kotlin
viewModelScope.launch {
    val result = withContext(Dispatchers.IO) { repo.fetchData() }
    _uiState.update { it.copy(data = result) }
}
```

`Dispatchers.Main` for UI, `IO` for network/DB/files, `Default` for CPU work. Never launch coroutines from composables directly -- use `LaunchedEffect`.

## Hilt DI

`@Singleton` for database, Retrofit, caches. No scope for repositories (cheap). `@ViewModelScoped` for shared ViewModel data.

## Room

```kotlin
@Dao
interface OrderDao {
    @Query("SELECT * FROM `Order` WHERE status = :status")
    fun getByStatus(status: String): Flow<List<Order>>  // reactive
}
```

DAOs return `Flow` for reactive queries. Store money as `Long` (cents), not `Double`.

## Testing

| What | Framework | Approach |
|---|---|---|
| ViewModel | JUnit + Turbine | Test state transitions via StateFlow |
| Compose UI | ComposeTestRule | `onNodeWithText("...").performClick()` |
| Repository | JUnit + MockK | Mock data sources |

```kotlin
@Test
fun `loadOrders updates state`() = runTest {
    val repo = mockk<OrderRepository> { coEvery { getOrders() } returns listOf(testOrder) }
    val vm = OrdersViewModel(repo)
    vm.loadOrders()
    assertEquals(listOf(testOrder), vm.uiState.value.orders)
}
```

## Common Pitfalls

| Pitfall | Why it breaks | Fix |
|---|---|---|
| I/O on Main thread | ANR | `withContext(Dispatchers.IO)` |
| `remember` state survives rotation | Lost on config change | Use `rememberSaveable` or ViewModel |
| Leaking coroutine scope | Memory leak | Use `viewModelScope` or `LaunchedEffect` |
| Exposing MutableStateFlow | UI modifies state directly | `.asStateFlow()` |
| Complex object in nav route | Serialization issues | Pass ID, load in destination ViewModel |
| Not testing ViewModel independently | Slow, needs Android | ViewModel is plain Kotlin -- JUnit |
