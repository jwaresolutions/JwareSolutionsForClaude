# Domain: Node.js (Express / Fastify)
**Loaded when:** Agent is building or modifying a Node.js HTTP API with Express or Fastify.
**Key concern:** Unhandled promise rejections. A single unhandled rejection crashes the process. Every async handler must catch errors.

---

## Middleware Pipeline

Order matters: `CORS -> Auth -> Validation -> Handler -> Error Handler`

```javascript
app.use(cors(corsOptions));
app.use(helmet());
app.use(express.json({ limit: '1mb' }));
app.use('/api', authMiddleware);
app.use('/api', routes);
app.use(errorHandler);  // MUST be last
```

## Async Error Handling

Express does not catch async rejections. Unhandled rejection = process crash.

```javascript
// Option 1: wrapper
const asyncHandler = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);
app.get('/orders', asyncHandler(async (req, res) => { /* ... */ }));

// Option 2: require('express-async-errors') -- patches Express globally
// Option 3: use Fastify -- handles async natively
```

## Centralized Error Handler

```javascript
// MUST have 4 params -- Express identifies error handlers by arity
app.use((err, req, res, next) => {
    const status = err.statusCode || 500;
    logger.error('request_failed', { error: err.message, stack: err.stack, path: req.path });
    res.status(status).json({ error: { message: status === 500 ? 'Internal server error' : err.message } });
});
```

Never send stack traces to client. Log full error server-side. Consistent error shape across endpoints.

## Input Validation

Validate every request before the handler. Use validated output, not raw `req.body`.

```javascript
const { z } = require('zod');
const CreateOrderSchema = z.object({
    symbol: z.string().min(1).max(10),
    quantity: z.number().int().positive(),
    side: z.enum(['buy', 'sell']),
});

function validate(schema) {
    return (req, res, next) => {
        const result = schema.safeParse(req.body);
        if (!result.success) return res.status(400).json({ error: { details: result.error.issues } });
        req.validated = result.data;
        next();
    };
}
```

## Configuration

Fail fast at startup if required env vars are missing.

```javascript
const required = ['DATABASE_URL', 'JWT_SECRET'];
for (const key of required) {
    if (!process.env[key]) throw new Error(`Missing env var: ${key}`);
}
```

## Graceful Shutdown

```javascript
process.on('SIGTERM', async () => {
    server.close();        // stop accepting connections
    await db.end();        // close database pool
    process.exit(0);
});
```

Without this, in-flight requests drop and connections leak on container stop.

## Project Structure

`routes/` -> `services/` -> `repositories/` -> database. No layer skips another. Middleware (auth, validation, error handler) in `middleware/`.

## Testing

Use supertest for HTTP-level integration tests. Mock at service/repository boundary. Cover: happy path, validation errors (400), auth errors (401), not-found (404).

## Common Pitfalls

| Pitfall | Why it breaks | Fix |
|---|---|---|
| Unhandled async rejection | Crashes process | asyncHandler or express-async-errors |
| Error handler not last | Errors uncaught | Register after all routes |
| Error handler with 3 params | Treated as regular middleware | Must have 4: `(err, req, res, next)` |
| No input validation | Injection, type errors | Zod/Joi before handler |
| Using raw `req.body` | Unvalidated, extra fields | Use `result.data` |
| Blocking event loop | All requests stall | Worker threads for CPU work |
| No graceful shutdown | Dropped requests, leaked connections | Handle SIGTERM/SIGINT |
| `console.log` in production | No structure, levels, context | Structured logger (pino) |
