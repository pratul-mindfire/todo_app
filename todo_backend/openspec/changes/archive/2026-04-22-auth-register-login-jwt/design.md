## Context

Greenfield implementation — no auth layer exists. The project is a Node.js/Express/MongoDB API. All source files under `src/` are yet to be written (prescribed by SDS). This change introduces the complete auth foundation that every subsequent feature depends on.

Constraints from AGENTS.md and SDS:
- Layered MVC strictly: Routes → Controllers → Models; no logic in route files.
- Mongoose only — no raw MongoDB driver.
- All responses use `{ success: boolean, ... }` envelope.
- Secrets via `process.env` only; never hardcoded.
- `express-validator` chosen by team for input validation (confirmed in requirements).

## Goals / Non-Goals

**Goals:**
- `POST /api/auth/register` — validate, hash, persist, return JWT + user.
- `POST /api/auth/login` — verify credentials, return JWT + user.
- `GET /api/auth/me` — protected route, returns current user profile.
- Auth middleware that verifies Bearer tokens and attaches `req.user`.
- Input validation via `express-validator` on both mutation endpoints.
- 409 Conflict on duplicate email registration.

**Non-Goals:**
- Refresh tokens (future scope per FRS §6).
- Role-based access control.
- Rate limiting.
- Todo CRUD endpoints.
- Email verification or password reset.

## Decisions

### 1. Register returns JWT (auto-login on signup)
Both `register` and `login` return `{ success, token, user }`. The FRS originally omitted the token from register; updated based on team input. Avoids the client needing two sequential requests after signup.

*Alternative considered*: Return user only, require separate login. Rejected — adds latency with no security benefit.

### 2. `express-validator` for input validation
Validation logic lives in route-level middleware arrays, keeping controllers thin. Each route file imports a `validate` middleware from a small array of `check()` rules. Errors collected with `validationResult` and short-circuited before the controller runs.

*Alternative considered*: Joi schema validation. Not chosen — adds another dependency; `express-validator` integrates more naturally with Express middleware chains.

*Alternative considered*: Manual if-checks in controller. Rejected — harder to extend, violates single-responsibility.

### 3. Auth middleware attaches `req.user` as `{ _id }`
Middleware decodes the JWT and attaches only `{ _id: payload.id }` to `req.user`. Controllers that need the full user profile fetch it from the DB. This avoids stale cached data in long-lived tokens.

*Alternative considered*: Embed full user object in JWT payload. Rejected — payload bloat and stale data risk if user details change within the 7-day window.

### 4. Duplicate email → 409 Conflict
Semantically distinct from validation errors (400). API consumers can reliably distinguish "invalid input" from "resource already exists."

### 5. Token generation isolated in `src/utils/generateToken.js`
Single place to change expiry or signing algorithm. Pure function: `(userId) → token`.

## Risks / Trade-offs

- **Stateless JWT, no revocation** → A leaked token is valid for 7 days. Mitigation: keep expiry at 7d and plan refresh-token rotation as follow-up. Not a blocker for MVP.
- **bcrypt cost factor default** → Using bcrypt's default (10 rounds) balances security and response time. At very high load this could become a bottleneck. Mitigation: externalize cost factor to env var if tuning is needed later.
- **express-validator added dependency** → Lightweight and widely maintained; risk is low.

## Migration Plan

Greenfield — no migration required. Deployment steps:
1. `npm install express-validator` (confirm with team per CLAUDE.md policy).
2. Populate `.env` with `PORT`, `MONGO_URI`, `JWT_SECRET`.
3. Run `npm run lint && npm test`.
4. Smoke-check: `node server.js` → POST `/api/auth/register` → GET `/api/auth/me`.

Rollback: revert files; no schema migration to undo (collection is created lazily by Mongoose).

## Open Questions

- None blocking. Confirmed: token on register, express-validator, /me route, 409 on duplicate.
