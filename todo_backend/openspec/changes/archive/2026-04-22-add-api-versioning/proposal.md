## Why

As the API grows to include Todo CRUD and future resources, clients need a stable contract that can evolve without breaking existing integrations. Introducing versioning now — before the API is widely consumed — avoids a more disruptive retrofit later.

## What Changes

- All API routes are prefixed with a version segment read from `API_VERSION` env var (e.g. `/api/v1/auth/*`).
- The version prefix is assembled in a single place (`src/app.js`) so bumping to v2 requires one change.
- Existing unversioned routes (`/api/auth/*`) remain functional by forwarding transparently to the versioned equivalents — no existing client breaks.
- `.env` gains a new `API_VERSION=v1` variable.
- Future route groups (e.g. Todo CRUD) are mounted under the same versioned prefix automatically.

## Capabilities

### New Capabilities

- `api-versioning`: Versioning contract — how the prefix is constructed from `API_VERSION`, how unversioned routes are forwarded, and what the guarantee is for clients on each version.

### Modified Capabilities

- `user-auth`: Route paths in all scenarios change from `/api/auth/*` to `/api/v1/auth/*` (the canonical paths are now versioned).

## Impact

- **Modified files**: `src/app.js` (mount point changes), `.env` (new var), `.env` template
- **New behavior**: `GET /api/auth/register` forwards to `GET /api/v1/auth/register` (and equivalent for login, me)
- **No breaking changes** for existing clients — unversioned paths continue to work
- **Future routes**: any new router mounted in `src/app.js` automatically inherits the version prefix
- **No new npm dependencies**
