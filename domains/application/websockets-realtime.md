# Domain: WebSockets & Real-Time
**Loaded when:** Agent is implementing or modifying WebSocket connections, real-time data feeds, or push-based communication.
**Key concern:** Connection lifecycle management. A WebSocket that silently dies without reconnection leaves the user looking at stale data.

---

## Connection Lifecycle

```
DISCONNECTED -> CONNECTING -> CONNECTED -> AUTHENTICATED -> SUBSCRIBED
      ^                                                          |
      +------ RECONNECTING <--- DISCONNECTED (unexpected) <-----+
```

Handle all transitions: `onopen` (reset retry count, authenticate), `onclose` (reconnect if not clean), `onerror` (reconnect). After reconnect, re-authenticate and re-subscribe -- the server does not remember previous sessions.

## Message Format

All messages use typed JSON with a `type` discriminant:

```typescript
type ClientMessage =
  | { type: "authenticate"; token: string }
  | { type: "subscribe"; channels: string[] }
  | { type: "unsubscribe"; channels: string[] }
  | { type: "ping" };

type ServerMessage =
  | { type: "authenticated"; userId: string }
  | { type: "data"; channel: string; payload: unknown }
  | { type: "error"; code: string; message: string }
  | { type: "pong" };
```

Route messages with a discriminated switch on `type`. Unknown types must log a warning, not crash.

## Reconnection with Exponential Backoff

When a connection drops unexpectedly, reconnect with capped exponential backoff plus jitter:

```typescript
const delay = Math.min(1000 * Math.pow(2, this.reconnectAttempts), 30000);
const jitter = delay * 0.2 * Math.random();
setTimeout(() => this.connect(this.url), delay + jitter);
```

| Attempt | Base delay | Cap |
|---|---|---|
| 0 | 1s | -- |
| 1 | 2s | -- |
| 2 | 4s | -- |
| 3 | 8s | -- |
| 5+ | 30s | 30s max |

Stop reconnecting after a max attempt count (e.g., 10). Surface the failure to the user -- do not retry forever silently.

## Stale Connection Detection

WebSocket connections can die silently (network change, proxy timeout). Use ping/pong heartbeats:

- Client sends `ping` every 30 seconds
- Server responds with `pong`
- If no `pong` received within 60 seconds, close and reconnect
- Server evicts connections that miss 2+ pong cycles (90s cutoff)

## Server-Side: Broadcasting

Use a `ConnectionManager` that maps `user_id -> WebSocket`. On broadcast, catch `WebSocketDisconnect` per-connection and remove dead connections from the map. A dead client must not break broadcast to other clients.

## Testing Requirements

| Scenario | What to verify |
|---|---|
| Connect + authenticate | State transitions to `authenticated` |
| Message parsing | Each `type` routes to correct handler |
| Malformed message | Error response, connection not dropped |
| Unexpected disconnect | Triggers reconnect with backoff |
| Stale connection | Detected and evicted after missed pongs |
| Max retries exhausted | Stops reconnecting, surfaces error to user |
| Broadcast to N clients | All connected clients receive message |
| Broadcast with dead client | Dead client removed, others unaffected |

## Common Pitfalls

| Pitfall | Why it breaks | Fix |
|---|---|---|
| No reconnection logic | User sees stale data forever | Implement exponential backoff reconnect |
| No heartbeat/ping-pong | Silent connection death undetected | Ping every 30s, evict after 90s |
| No jitter on reconnect | Thundering herd after server restart | Add random jitter to backoff delay |
| Parsing without type check | Runtime crash on unknown message type | Validate `type` field before handling |
| No stale connection eviction | Server accumulates dead connections | Evict based on last pong timestamp |
| Reconnect without re-auth | Server rejects unauthenticated messages | Re-authenticate after every reconnect |
