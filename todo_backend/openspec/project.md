# Project Context — Todo Backend API

## Overview

A RESTful backend API providing user registration, login, and JWT-based authentication. Written in Node.js/Express with MongoDB via Mongoose. Todo CRUD endpoints are planned but not yet in scope.

---

## Tech Stack

| Layer        | Technology                     |
|--------------|--------------------------------|
| Runtime      | Node.js                        |
| Framework    | Express.js                     |
| Database     | MongoDB (no SQL databases)     |
| ODM          | Mongoose only (no raw driver)  |
| Auth         | `jsonwebtoken`, expiry `7d`    |
| Hashing      | `bcrypt`                       |

---

## Repository Structure

```
todo-backend/
├── src/
│   ├── config/db.js              # Mongoose connection
│   ├── models/User.js            # User schema/model
│   ├── controllers/authController.js
│   ├── routes/authRoutes.js
│   ├── middleware/authMiddleware.js
│   ├── utils/generateToken.js    # jwt.sign helper (pure, no side effects)
│   └── app.js                    # Express setup, route mounting
├── server.js                     # HTTP entry point
├── docs/FRS.md
├── docs/SDS.md
├── package.json
└── .env                          # Never committed
```

---

## Architecture Constraints

- **Layered MVC only**: Routes → Controllers → Models. No business logic in route files or model files.
- **Request lifecycle**: Client → Route → (Auth Middleware on protected routes) → Controller → Model → Response.
- **Config isolation**: DB connection and env access live in `src/config/`; no inline secrets anywhere.
- **Utilities are pure**: `src/utils/` functions have no side effects.
- **No raw MongoDB driver**: all DB access goes through Mongoose.

---

## API Conventions

All routes prefixed `/api/`.

| Method | Path               | Auth | Description      |
|--------|--------------------|------|------------------|
| POST   | /api/auth/register | No   | Create new user  |
| POST   | /api/auth/login    | No   | Login, get token |

**Success envelope:**
```json
{ "success": true, "token": "...", "user": { "id": "...", "name": "...", "email": "..." } }
```

**Error envelope:**
```json
{ "success": false, "message": "Human-readable error" }
```

- HTTP 200 success · 400 validation/client · 401 auth failure · 500 server error.
- Never expose stack traces or internal error detail in `message`.
- Never return or log the `password` field.

---

## Auth Design

- Token transport: `Authorization: Bearer <token>` header.
- Auth middleware: extract → verify → attach `user._id` to `req.user` → `next()`, or return 401.
- Token generation centralized in `src/utils/generateToken.js`.
- Passwords stored as bcrypt hashes only; plaintext never persisted.

---

## Data Model

**Collection: `users`**

| Field     | Type   | Constraints           |
|-----------|--------|-----------------------|
| name      | String | required              |
| email     | String | required, unique      |
| password  | String | required, bcrypt hash |
| createdAt | Date   | auto-set              |

---

## Coding Conventions

- **Naming**: camelCase for variables/functions · PascalCase for models/classes · kebab-case for filenames.
- **Response shape**: always `{ success: boolean, ... }` — no bare objects.
- **Async errors**: always caught; standard error shape returned.
- **Env vars**: `process.env.VAR_NAME` only; no hardcoded secrets.

---

## Quality Standards

Run in this order; all must pass before marking a task complete:

1. `npm run lint` — zero errors
2. `npm test` — zero failures
3. `node server.js` smoke check — server starts without errors

---

## Environment Variables

```env
PORT=5000
MONGO_URI=<mongodb connection string>
JWT_SECRET=<signing secret>
```

---

## Do NOT Do

- Business logic in route files.
- Return or log the `password` field.
- Hardcode secrets or connection strings.
- Use SQL or any database other than MongoDB.
- Bypass Mongoose with raw driver calls.
- Swallow errors silently.
- Add features outside defined scope without updating FRS/SDS first.

---

## Future Scope (out of current scope)

- Todo CRUD APIs (new collection required)
- Refresh tokens
- Role-based access control
- Rate limiting
