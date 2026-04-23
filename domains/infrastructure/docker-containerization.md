# Domain: Docker & Containerization
**Loaded when:** Agent is writing Dockerfiles, configuring Docker Compose, or managing container builds.
**Key concern:** Build reproducibility. A container that builds differently tomorrow than today is a ticking time bomb.

---

## Multi-Stage Builds

Separate build dependencies from runtime. Final image contains only what the app needs to run.

```dockerfile
FROM node:20-slim AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --ignore-scripts
COPY src/ src/
RUN npm run build

FROM node:20-slim AS runtime
WORKDIR /app
RUN addgroup --system app && adduser --system --ingroup app app
COPY --from=build /app/dist ./dist
COPY --from=build /app/node_modules ./node_modules
USER app
HEALTHCHECK --interval=30s --timeout=3s CMD curl -f http://localhost:3000/health || exit 1
CMD ["node", "dist/server.js"]
```

## Layer Caching

Order instructions least-changing to most-changing. Copy dependency files before source.

```dockerfile
# WRONG                          # RIGHT
COPY . .                         COPY package.json package-lock.json ./
RUN npm ci                       RUN npm ci
                                 COPY . .
```

## Image Bases

| Base | Size | Use when |
|---|---|---|
| `alpine` | ~5 MB | Go, Rust binaries (watch for musl vs glibc) |
| `slim` | ~80 MB | Python, Node (fewer surprises) |
| `distroless` | ~20 MB | Production-only, no shell |

Target under 200 MB final image. Never use `latest` tag -- pin to specific version.

## Security

**Non-root user (non-negotiable):**
```dockerfile
RUN addgroup --system app && adduser --system --ingroup app app
USER app
```

**Secrets -- never bake into image:**
```dockerfile
# WRONG: visible in docker history
ENV DATABASE_URL=postgres://user:pass@host/db
ARG DB_PASSWORD

# RIGHT: runtime injection via docker run -e or compose env_file
# For build-time secrets:
RUN --mount=type=secret,id=npm_token NPM_TOKEN=$(cat /run/secrets/npm_token) npm ci
```

**.dockerignore (always create one):** `.git`, `node_modules`, `.env`, `__pycache__`, `.vscode`

## Health Checks

Without a health check, orchestrators assume the container is healthy if the process runs -- even if deadlocked.

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1
```

## Docker Compose

```yaml
services:
  app:
    build: .
    ports: ["3000:3000"]
    depends_on:
      db: { condition: service_healthy }
  db:
    image: postgres:16
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
```

Use `condition: service_healthy` so the app waits for the database to be ready, not just started.

## Common Pitfalls

| Pitfall | Why it breaks | Fix |
|---|---|---|
| Running as root | Container escape = host root | `USER app` |
| No `.dockerignore` | Slow builds, secrets leak | Create with sensible defaults |
| `COPY . .` before deps install | Busts cache on every change | Copy lockfile first, install, then source |
| `latest` tag | Non-reproducible builds | Pin versions |
| Secrets in ENV/ARG | Visible in `docker history` | Runtime injection or `--mount=type=secret` |
| No health check | Orchestrator can't detect failures | Add HEALTHCHECK |
| Dev deps in production | Bloat, security risk | Multi-stage: separate build and runtime |
