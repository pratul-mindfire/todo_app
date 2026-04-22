# AGENTS.md — Todo Backend API

Single source of truth for all AI tools on this team. Keep this file up to date as the project evolves.

---

## 1. Project Overview

A RESTful backend API built with Node.js, Express, and MongoDB that handles user registration and login with JWT-based authentication. The service stores hashed credentials in MongoDB and protects downstream routes via auth middleware. Todo CRUD APIs are planned but not yet implemented.

---

## 2. Repository Structure

```
todo-backend/
├── docs/
│   ├── FRS.md              # Functional requirements
│   └── SDS.md              # Software design spec
├── src/
│   ├── config/
│   │   └── db.js           # Mongoose connection setup
│   ├── models/
│   │   └── User.js         # User Mongoose schema/model
│   ├── controllers/
│   │   └── authController.js  # register + login logic
│   ├── routes/
│   │   └── authRoutes.js   # Route definitions for /api/auth/*
│   ├── middleware/
│   │   └── authMiddleware.js  # JWT verification, attaches user to req
│   ├── utils/
│   │   └── generateToken.js   # jwt.sign helper
│   └── app.js              # Express app setup, mounts routes
├── server.js               # Entry point, starts HTTP server
├── package.json
└── .env                    # Never commit — see env vars section
```

> Note: Source code is not yet written. This structure is prescribed by the SDS.

---

## 3. Tech Stack

| Layer        | Technology            |
|--------------|-----------------------|
| Runtime      | Node.js               |
| Framework    | Express.js            |
| Database     | MongoDB               |
| ODM          | Mongoose              |
| Auth         | JWT (`jsonwebtoken`)  |
| Hashing      | bcrypt                |

No SQL databases. No ORMs. Mongoose only.

---

## 4. Key Commands

```bash
npm install          # Install dependencies
node server.js       # Start server (production)
nodemon server.js    # Start server (dev, hot reload)
npm test             # Run tests (framework TBD)
```

> `.env` must be populated before starting the server (see §9).

---

## 5. Architecture Patterns

- **Layered MVC**: Routes → Controllers → Models. No logic in routes or models beyond their layer.
- **Request lifecycle**: Client → Route → Controller → Model (DB) → Response.
- **Middleware chain**: Auth middleware sits between route and controller for protected endpoints.
- **Config isolation**: DB connection and env vars live in `src/config/`, never inline.
- **Utility helpers**: Pure functions in `src/utils/` (e.g., token generation) — no side effects.

---

## 6. Coding Standards

- **Naming**: camelCase for variables/functions, PascalCase for models and classes, kebab-case for file names.
- **Error handling**: Always catch async errors; return standard error shape (see §8). Never leak stack traces.
- **Response shape**: All responses use `{ success: boolean, ... }` envelope — no bare objects.
- **Password**: Never return or log the `password` field. Strip it from all responses.
- **Env vars**: Access via `process.env.VAR_NAME`; no hardcoded secrets anywhere.

---

## 7. Auth Approach

- **Mechanism**: JWT, signed with `JWT_SECRET`, expiry `7d`.
- **Token transport**: `Authorization: Bearer <token>` request header.
- **Middleware behavior**: Extracts token → verifies → attaches `user._id` to `req.user` → calls `next()`. Returns 401 on failure.
- **Password storage**: bcrypt hash only; plaintext never persisted.
- **Token generation**: Centralized in `src/utils/generateToken.js`.

---

## 8. API Design Conventions

All routes are prefixed `/api/`.

| Method | Path                  | Auth required | Description        |
|--------|-----------------------|---------------|--------------------|
| POST   | /api/auth/register    | No            | Create new user    |
| POST   | /api/auth/login       | No            | Login, get token   |

**Success response shape:**
```json
{ "success": true, "token": "...", "user": { "id": "...", "name": "...", "email": "..." } }
```

**Error response shape:**
```json
{ "success": false, "message": "Human-readable error" }
```

- HTTP 200 for success, 400 for validation/client errors, 401 for auth failures, 500 for server errors.
- Never expose internal error details in the `message` field in production.

---

## 9. DB Schema Summary

**Collection: `users`**

| Field       | Type    | Constraints          |
|-------------|---------|----------------------|
| name        | String  | required             |
| email       | String  | required, unique     |
| password    | String  | required, bcrypt hash|
| createdAt   | Date    | auto-set             |

No other collections yet. Todo collection is future scope.

---

## 10. Testing Approach

- Testing framework is not yet defined (future scope).
- Tests should live in `src/__tests__/` or alongside source files as `*.test.js`.
- Minimum coverage targets: auth controller happy paths + validation failures.
- Run with: `npm test`.

---

## 11. Do NOT Do

- Do not write business logic in route files — keep routes thin.
- Do not return the `password` field in any response or log.
- Do not hardcode secrets, connection strings, or tokens — use `.env`.
- Do not commit `.env` to version control.
- Do not use SQL or any database other than MongoDB.
- Do not bypass Mongoose — no raw MongoDB driver calls.
- Do not swallow errors silently; always return the standard error shape.
- Do not add features outside the defined scope without updating FRS/SDS first.

---

## 12. Shared Packages

No `/packages/shared` directory exists yet. If shared utilities are extracted in the future (e.g., validation helpers, response formatters), they should live there and be documented in this section.

---

## Environment Variables

```env
PORT=5000
MONGO_URI=your_mongodb_connection_string
JWT_SECRET=your_secret_key
```
