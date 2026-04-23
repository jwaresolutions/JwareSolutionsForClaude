# Domain: Wear OS Development
**Loaded when:** Agent is building or modifying a Wear OS watch application.
**Key concern:** Battery life. A watch has a tiny battery. Anything that keeps the CPU awake or updates the screen frequently will drain it in hours.

---

## Constraints

| Resource | Limit |
|---|---|
| Screen | 1.1-1.4" round OR square |
| Battery | 250-400 mAh |
| Input | Touch, rotary crown, 1-2 buttons |
| Interaction time | Under 5 seconds |
| Connectivity | Bluetooth to phone, occasional Wi-Fi |

## Compose for Wear OS

Import from `androidx.wear.compose`, NOT `androidx.compose`. Different composables:

| Phone | Wear OS | Why |
|---|---|---|
| `LazyColumn` | `ScalingLazyColumn` | Scales items at edges for round screen |
| `TopAppBar` | `TimeText` | Shows time (required by guidelines) |
| `Scaffold` | `Scaffold` (wear) | Includes `TimeText`, `Vignette`, `PositionIndicator` |

```kotlin
@Composable
fun WorkoutScreen() {
    Scaffold(
        timeText = { TimeText() },
        vignette = { Vignette(vignettePosition = VignettePosition.TopAndBottom) },
    ) {
        ScalingLazyColumn(modifier = Modifier.fillMaxSize()) {
            item { TitleCard(title = { Text("Current Run") }, onClick = {}) { Text("5.2 km") } }
            item { Chip(label = { Text("Pause") }, onClick = {}) }
        }
    }
}
```

Always support **rotary crown** for scrolling via `onRotaryScrollEvent` + `focusRequester`.

## Ambient Mode (Non-Negotiable)

Watches must support ambient mode -- low-power screen when wrist is down. Without it, battery drains in hours.

**Burn-in protection (OLED):**
- Shift content by a few pixels each update
- Use outlines, not filled shapes
- Avoid large solid-color regions
- Update at most once per minute

## Background Work

**Alarms:** Use `AlarmManager.setExactAndAllowWhileIdle` for time-critical work. All alarms are cleared on reboot -- register a `BOOT_COMPLETED` receiver to reschedule.

```xml
<receiver android:name=".BootReceiver" android:exported="false">
    <intent-filter><action android:name="android.intent.action.BOOT_COMPLETED" /></intent-filter>
</receiver>
```

**Non-urgent work:** Use `WorkManager` with network constraints. Wear OS aggressively enters doze mode.

## Complications

Small data slots on the watch face. Most battery-efficient way to show data -- the watch face renders them, not your app. Implement `SuspendingComplicationDataSourceService`, register supported types in manifest.

## Data Storage

| Storage | Use for |
|---|---|
| `DataStore` | Simple key-value settings |
| Room | Structured local data |
| DataLayer API | Syncing between watch and phone |

Keep storage minimal. Limited space and I/O performance.

## Screen Shape

**Always test on both round AND square.** Use `ScalingLazyColumn` and standard Wear Compose components -- they handle shape differences. Custom layouts need `LocalConfiguration.current.isScreenRound`.

## Common Pitfalls

| Pitfall | Why it breaks | Fix |
|---|---|---|
| No ambient mode | Battery drains in hours | Implement ambient callbacks |
| OLED burn-in | Permanent screen damage | Shift content, outlines, no solid fills |
| Complex navigation | Users abandon after 2 taps | Max 2 levels deep |
| Frequent network requests | Battery drain | Batch, cache, use WorkManager |
| Testing only one screen shape | UI broken on other | Test both round and square |
| Wake locks | Battery drain, system kills app | Use AlarmManager or WorkManager |
| Not rescheduling after reboot | Alarms stop | BOOT_COMPLETED receiver |
| Phone Compose imports | Wrong components | `androidx.wear.compose.*` |
