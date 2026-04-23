# Domain: Next.js + React
**Loaded when:** Agent is implementing or modifying frontend pages, components, or build configuration.
**Key concern:** This project uses static export (`output: "export"`). Server-side features (SSR, API routes, server components) do not work.

---

## Static Export Constraints

With `output: "export"` in `next.config.js`, the build produces static HTML/JS/CSS files served from a CDN (Cloudflare Pages). This means:

| Feature | Available? | Alternative |
|---|---|---|
| Server Components | No | Use `"use client"` directive |
| API Routes (`/api/*`) | No | Separate backend (FastAPI) |
| `getServerSideProps` | No | Client-side fetch in `useEffect` |
| `getStaticProps` | Yes (build-time only) | Use for truly static data |
| Middleware | No | Handle at CDN/backend level |
| Image Optimization | No (no server) | Use `<img>` or external optimizer |
| Dynamic routes | Limited | Must use `generateStaticParams` |

Every component that uses hooks, browser APIs, or interactivity must have `"use client"` at the top. In static export, this is nearly every component. For layouts needing client-side state (auth, theme, WebSocket), use a client-shell wrapper component in `app/layout.tsx`.

## Environment Variables

`NEXT_PUBLIC_*` variables are baked into the JS bundle at build time. Changing them requires a rebuild and redeploy. Variables without the `NEXT_PUBLIC_` prefix are not available in client code. There is no runtime configuration in static export.

## Route-Based Code Organization

```
app/
  layout.tsx           # Root layout (client shell)
  page.tsx             # Home page
  dashboard/
    page.tsx           # /dashboard
  backtest/
    page.tsx           # /backtest
  portfolio/
    page.tsx           # /portfolio
components/
  backtest/            # Components for backtest feature
  portfolio/           # Components for portfolio feature
  shared/              # Shared components (buttons, modals, etc.)
lib/
  api.ts               # API client functions
  hooks/               # Custom React hooks
```

## Data Fetching

All data fetching is client-side via `useEffect` + API client functions. Every data component must handle four states: loading, error, empty, populated.

## Dynamic Imports

For heavy components (charts, editors), use `next/dynamic` with `ssr: false` (required for static export) and a loading placeholder.

## Common Pitfalls

| Pitfall | Why it breaks | Fix |
|---|---|---|
| Missing `"use client"` | Build error or hydration mismatch | Add directive to any file using hooks/browser APIs |
| Server Components | Not supported in static export | Always use client components |
| `process.env.X` without `NEXT_PUBLIC_` prefix | Undefined at runtime (not bundled) | Use `NEXT_PUBLIC_` prefix for client-side vars |
| Changing env vars without rebuild | Old values baked into bundle | Rebuild and redeploy after changes |
| Using `next/image` optimization | No server to optimize images | Use `<img>` or configure external loader |
| API routes in `app/api/` | Not generated in static export | Use separate backend |
| Missing `ssr: false` on dynamic imports | Fails during static generation | Always set `ssr: false` |
