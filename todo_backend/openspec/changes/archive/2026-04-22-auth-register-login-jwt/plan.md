# Implementation Plan — auth-register-login-jwt

> Status: **PENDING APPROVAL** — do not implement until approved.

---

## 1. Scope Summary

Completely greenfield. No `src/` files, no `package.json`, no `server.js` exist. This plan creates the full project scaffold and the auth layer in one pass.

---

## 2. Files to Create

Listed in creation order (dependencies first):

```
package.json                              ← project manifest + scripts
.gitignore                                ← exclude node_modules, .env
.eslintrc.json                            ← ESLint config (required for npm run lint)
.env                                      ← PORT, MONGO_URI, JWT_SECRET (never committed)
src/
  config/
    db.js                                 ← Mongoose connect helper
  models/
    User.js                               ← User schema
  utils/
    generateToken.js                      ← jwt.sign pure helper
  middleware/
    authMiddleware.js                     ← Bearer token verifier
  controllers/
    authController.js                     ← registerUser, loginUser, getMe
  routes/
    authRoutes.js                         ← route definitions + validation chains
  app.js                                  ← Express instance + route mounting
server.js                                 ← HTTP entry point
```

No existing files are modified (greenfield).

---

## 3. Object Shapes (API Contracts)

### Request bodies

```js
// POST /api/auth/register
{ name: string, email: string, password: string /* ≥ 6 chars */ }

// POST /api/auth/login
{ email: string, password: string }
```

### Success responses

```js
// POST /api/auth/register  (HTTP 200)
// POST /api/auth/login     (HTTP 200)
{ success: true, token: string, user: { id: string, name: string, email: string } }

// GET /api/auth/me         (HTTP 200)
{ success: true, user: { id: string, name: string, email: string } }
```

### Error responses

```js
// HTTP 400 — validation failure
{ success: false, message: string }   // first failing rule's message

// HTTP 401 — auth failure
{ success: false, message: "Invalid credentials" }          // login mismatch
{ success: false, message: "Not authorized, no token" }     // missing header
{ success: false, message: "Not authorized, token failed" } // bad/expired JWT

// HTTP 409 — duplicate email
{ success: false, message: "Email already registered" }

// HTTP 500 — unexpected server error
{ success: false, message: "Server error" }
```

### JWT payload

```js
{ id: string /* user._id.toString() */, iat: number, exp: number /* +7d */ }
```

### `req.user` (after middleware)

```js
{ _id: ObjectId }   // full user fetched by controller only when needed
```

### Mongoose User document

```js
{
  _id:       ObjectId,
  name:      String,   // required
  email:     String,   // required, unique, stored lowercase
  password:  String,   // required, bcrypt hash — never returned
  createdAt: Date      // default: Date.now
}
```

---

## 4. File-by-file Implementation Plan

### `package.json`
```json
{
  "name": "todo-backend",
  "version": "1.0.0",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js",
    "lint": "eslint src/ server.js --ext .js",
    "test": "jest --passWithNoTests"
  },
  "dependencies": {
    "bcrypt": "^5.x",
    "dotenv": "^16.x",
    "express": "^4.x",
    "express-validator": "^7.x",
    "jsonwebtoken": "^9.x",
    "mongoose": "^8.x"
  },
  "devDependencies": {
    "eslint": "^8.x",
    "jest": "^29.x",
    "nodemon": "^3.x"
  }
}
```
> `--passWithNoTests` keeps `npm test` green until real tests are written (AGENTS.md §10: "Testing framework not yet defined").

---

### `.eslintrc.json`
```json
{
  "env": { "node": true, "es2021": true },
  "extends": "eslint:recommended",
  "parserOptions": { "ecmaVersion": 2021 },
  "rules": { "no-unused-vars": "warn", "no-console": "off" }
}
```

---

### `src/config/db.js`
- Export `async function connectDB()`.
- `mongoose.connect(process.env.MONGO_URI)` — throw on failure so `server.js` can handle it.
- Log the connected host on success.

---

### `src/models/User.js`
- Schema fields: `name` (String, required), `email` (String, required, unique, lowercase: true, trim: true), `password` (String, required), `createdAt` (Date, default: Date.now).
- `lowercase: true` on email enforces case-insensitive uniqueness (spec requirement).
- Export `mongoose.model('User', userSchema)`.

---

### `src/utils/generateToken.js`
- Single export: `const generateToken = (userId) => jwt.sign({ id: userId }, process.env.JWT_SECRET, { expiresIn: '7d' })`.
- Pure — no imports beyond `jsonwebtoken`, no side effects.

---

### `src/middleware/authMiddleware.js`
Decision: attach `{ _id }` only, never cache full user in token.

```
protect(req, res, next):
  1. Read req.headers.authorization
  2. If missing or not "Bearer ..." → 401 "Not authorized, no token"
  3. token = header.split(' ')[1]
  4. try { decoded = jwt.verify(token, JWT_SECRET) }
     catch → 401 "Not authorized, token failed"
  5. req.user = { _id: decoded.id }
  6. next()
```

---

### `src/controllers/authController.js`

**`registerUser(req, res)`**
```
1. validationResult(req) — if errors, 400 with first error message
2. Destructure { name, email, password } from req.body
3. User.findOne({ email }) — if found, 409 "Email already registered"
4. hash = await bcrypt.hash(password, 10)
5. user = await User.create({ name, email, password: hash })
6. token = generateToken(user._id)
7. 200 { success: true, token, user: { id: user._id, name, email } }
```

**`loginUser(req, res)`**
```
1. validationResult(req) — if errors, 400 with first error message
2. Destructure { email, password } from req.body
3. user = await User.findOne({ email })
4. If !user OR !(await bcrypt.compare(password, user.password)) → 401 "Invalid credentials"
   (single branch — no hint whether email or password was wrong)
5. token = generateToken(user._id)
6. 200 { success: true, token, user: { id: user._id, name: user.name, email: user.email } }
```

**`getMe(req, res)`**
```
1. user = await User.findById(req.user._id).select('-password')
2. 200 { success: true, user: { id: user._id, name: user.name, email: user.email } }
```

All three handlers wrapped in `try/catch` → 500 `{ success: false, message: 'Server error' }`.

---

### `src/routes/authRoutes.js`

Validation chains (applied as middleware arrays, before controller):

```js
// register validation
[
  check('name',     'Name is required').notEmpty(),
  check('email',    'Valid email is required').isEmail(),
  check('password', 'Password must be at least 6 characters').isLength({ min: 6 }),
]

// login validation
[
  check('email',    'Email is required').notEmpty(),
  check('password', 'Password is required').notEmpty(),
]
```

`validate` helper (defined in this file, not exported):
```js
(req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty())
    return res.status(400).json({ success: false, message: errors.array()[0].msg });
  next();
}
```

Routes:
```
POST   /register  → [registerValidation, validate, registerUser]
POST   /login     → [loginValidation,    validate, loginUser]
GET    /me        → [protect,                       getMe]
```

---

### `src/app.js`
```
1. express()
2. app.use(express.json())
3. app.use('/api/auth', authRoutes)
4. module.exports = app
```

---

### `server.js`
```
1. require('dotenv').config()
2. const app = require('./src/app')
3. const connectDB = require('./src/config/db')
4. connectDB()
5. app.listen(process.env.PORT || 5000, () => console.log(`Server running on ${PORT}`))
```

---

## 5. Architecture Decisions

| Decision | Choice | Reason |
|---|---|---|
| Validation layer | `express-validator` in route middleware | Keeps controllers thin; declarative; easy to extend |
| Token on register | Yes — return JWT | Avoids double round-trip after signup |
| `req.user` content | `{ _id }` only | No stale data risk; controllers fetch fresh profile |
| Duplicate email status | 409 Conflict | Semantically distinct from 400 validation errors |
| Email storage | Lowercase (Mongoose `lowercase: true`) | Case-insensitive uniqueness without extra query logic |
| bcrypt rounds | 10 (default) | Balanced security/latency at MVP scale |
| Error message on bad login | Single "Invalid credentials" | Prevents user enumeration via timing/message differences |
| Token generation | Isolated util function | Single place to change secret, algorithm, or expiry |

---

## 6. Database Changes

No migration required. Mongoose creates the `users` collection lazily on first insert.

Backward-compatible: yes (new collection, no existing data).

Unique index on `email` is created automatically by Mongoose from `unique: true` in the schema. First `npm start` will build it.

---

## 7. Dependency Install Commands

> Per CLAUDE.md, confirm each before running.

```bash
# Core runtime deps
npm install express mongoose jsonwebtoken bcrypt dotenv express-validator

# Dev deps
npm install --save-dev eslint jest nodemon
```

---

## 8. Quality Gate Checkpoints

Run in this exact order after each group of files:

```bash
# After all files written:
npm run lint          # must exit 0, zero errors

# After lint passes:
npm test              # must exit 0 (--passWithNoTests flag handles empty suite)

# After tests pass:
node server.js        # server must log "Server running" and "MongoDB connected"

# Final smoke test (separate terminal):
# 1. Register
curl -s -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com","password":"secret123"}' | jq .

# 2. Login
curl -s -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"secret123"}' | jq .

# 3. Protected route (replace TOKEN with value from step 1 or 2)
curl -s http://localhost:5000/api/auth/me \
  -H "Authorization: Bearer TOKEN" | jq .
```

---

## 9. Out of Scope

The following are explicitly excluded from this implementation:
- Refresh tokens
- Role-based access control
- Rate limiting
- Todo CRUD endpoints
- ESLint auto-fix (`--fix`) — run lint, fix manually, commit clean
- `.env` committed to git — `.gitignore` must exclude it

---

## Approval Required

Do not begin implementation until this plan is approved. Once approved, run `/opsx:apply` to start working through `tasks.md`.
