## Why

The API has no authentication layer. Without register, login, and JWT middleware, no protected routes can exist and the service cannot be used by any client. This is the foundational capability that all future features (Todo CRUD, role-based access) depend on.

## What Changes

- New `POST /api/auth/register` endpoint: validates input, hashes password with bcrypt, persists user, and returns a JWT token so the client is immediately authenticated.
- New `POST /api/auth/login` endpoint: verifies credentials against stored hash, issues a JWT token on success.
- New `GET /api/auth/me` protected endpoint: smoke-tests the auth middleware end-to-end by returning the currently authenticated user's profile.
- New JWT auth middleware (`authMiddleware.js`): extracts and verifies the `Authorization: Bearer <token>` header, attaches `req.user._id`, and gates protected routes.
- Input validation via `express-validator` on both auth endpoints.
- Duplicate email registration returns `409 Conflict` (not 400).

## Capabilities

### New Capabilities

- `user-auth`: User registration and login endpoints — input validation, password hashing, JWT issuance, and the `/me` profile route.
- `auth-middleware`: JWT verification middleware that protects routes and attaches `req.user` to the request context.

### Modified Capabilities

<!-- None — no existing specs to delta. -->

## Impact

- **New files**: `src/controllers/authController.js`, `src/routes/authRoutes.js`, `src/middleware/authMiddleware.js`, `src/utils/generateToken.js`, `src/models/User.js`, `src/config/db.js`, `src/app.js`, `server.js`
- **New dependency**: `express-validator` (requires install confirmation per CLAUDE.md)
- **Existing dependencies**: `express`, `mongoose`, `jsonwebtoken`, `bcrypt`, `dotenv` (all already in scope per SDS)
- **API surface added**: `POST /api/auth/register`, `POST /api/auth/login`, `GET /api/auth/me`
- **Breaking changes**: none — greenfield implementation
