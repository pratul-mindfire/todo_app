## Context

Currently all routes are mounted at `/api/auth/*` with no version segment. The only file that defines mount points is `src/app.js`. There are no external consumers yet, so this is the lowest-risk moment to introduce versioning. The change must not break the existing `/api/auth/*` paths because the smoke tests and Vercel deployment already use them.

## Goals / Non-Goals

**Goals:**
- Canonical API paths become `/api/v1/auth/*` (and future `/api/v1/todo/*` etc.).
- `API_VERSION` env var controls the version segment — changing it to `v2` is a one-line `.env` edit.
- Old `/api/auth/*` paths continue to work transparently (same router, second mount point).
- Zero new npm dependencies.

**Non-Goals:**
- Multi-version routing (serving v1 and v2 simultaneously) — out of scope; one active version at a time.
- Version negotiation via headers or query params.
- Automatic deprecation headers on old paths (can be added later).
- Changing any controller, middleware, or model logic.

## Decisions

### 1. Dual-mount in `src/app.js` (not a redirect)
Mount the same `authRouter` at two prefixes:
```
app.use(`/api/${API_VERSION}/auth`, authRoutes)   // canonical
app.use('/api/auth', authRoutes)                   // backward-compat
```
A redirect (301/302) would force clients to follow an extra round-trip and would invalidate any caching. Dual-mount has zero overhead — the router instance is shared, no code duplication.

*Alternative considered*: Middleware redirect. Rejected — adds latency and complexity with no benefit for an internal API.

### 2. Version read at app startup from `API_VERSION` env var
`process.env.API_VERSION` is read once when `src/app.js` is required. If the variable is missing, the app falls back to `'v1'` so local dev without a populated `.env` doesn't crash.

*Alternative considered*: Hardcode `'v1'` as a constant. Rejected — user specifically requested env var configurability for multi-instance deployments.

### 3. Single assembly point — `src/app.js` only
No router file changes. No controller changes. Only `src/app.js` and `.env` are touched. Future route groups (Todo CRUD) are mounted the same way and automatically inherit the version prefix.

## Risks / Trade-offs

- **[Risk] Two mount points serve identical routes** → If a future middleware needs to distinguish versioned vs unversioned callers, both paths would match. Mitigation: add a `Deprecation` header on the unversioned mount when that distinction matters.
- **[Risk] `API_VERSION` typo silently changes all paths** → Mitigation: on startup, validate that `API_VERSION` matches `/^v\d+$/` and throw if not.
- **[Risk] Vercel deployment requires `API_VERSION` env var** → Mitigation: document in `.env` template and Vercel env var setup.

## Migration Plan

1. Add `API_VERSION=v1` to `.env` and Vercel environment variables.
2. Update `src/app.js` to dual-mount with versioned prefix.
3. Verify old URLs still work: `POST /api/auth/register` → 200.
4. Verify new URLs work: `POST /api/v1/auth/register` → 200.
5. Update all internal references (tests, smoke-test docs) to use versioned paths.
6. Rollback: remove the versioned mount line from `src/app.js` and the `API_VERSION` env var.

## Open Questions

- None blocking. Startup validation regex for `API_VERSION` is a nice-to-have, not required for MVP.
