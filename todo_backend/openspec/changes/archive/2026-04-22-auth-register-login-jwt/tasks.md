## Phase 1: Foundation

> Sequential — each task depends on the previous.

- [x] 1.1 Create `package.json` with scripts (`start`, `dev`, `lint`, `test`) and dependency stubs as specified in `plan.md §4`
- [x] 1.2 Confirm and run: `npm install express mongoose jsonwebtoken bcrypt dotenv express-validator`
- [x] 1.3 Confirm and run: `npm install --save-dev eslint jest supertest nodemon mongodb-memory-server`
- [x] 1.4 Create `.gitignore` — exclude `node_modules/`, `.env`, `coverage/`
- [x] 1.5 Create `.eslintrc.json` — `eslint:recommended`, node env, ecmaVersion 2021
- [x] 1.6 Create `.env` from template: `PORT=5000`, `MONGO_URI=<uri>`, `JWT_SECRET=<secret>`
- [x] 1.7 Create `src/config/db.js` — `async connectDB()` using `mongoose.connect(process.env.MONGO_URI)`, log host on success, throw on failure
- [x] 1.8 Create `src/models/User.js` — fields: `name` (String, required), `email` (String, required, unique, lowercase, trim), `password` (String, required), `createdAt` (Date, default: Date.now)
- [x] 1.9 Create `src/utils/generateToken.js` — pure function `(userId) => jwt.sign({ id: userId }, JWT_SECRET, { expiresIn: '7d' })`

**Checkpoint 1** — must pass before Phase 2:
```
npm run lint        # zero errors across src/
```

---

## Phase 2: Core Implementation

> Tasks 2.1–2.4 are PARALLEL (no shared state). Task 2.5 requires all four.

- [x] 2.1 [PARALLEL] Create `src/middleware/authMiddleware.js` — `protect(req, res, next)`: extract Bearer token → `jwt.verify` → attach `req.user = { _id: decoded.id }` → `next()`; 401 on missing header; 401 on verify failure
- [x] 2.2 [PARALLEL] Implement `registerUser` in `src/controllers/authController.js` — run `validationResult`, 400 on failure; `findOne` by email, 409 on duplicate; `bcrypt.hash`; `User.create`; `generateToken`; return `{ success, token, user: { id, name, email } }`
- [x] 2.3 [PARALLEL] Implement `loginUser` in `src/controllers/authController.js` — run `validationResult`, 400 on failure; `findOne` by email; `bcrypt.compare`; single 401 "Invalid credentials" on any mismatch; `generateToken`; return `{ success, token, user }`
- [x] 2.4 [PARALLEL] Implement `getMe` in `src/controllers/authController.js` — `User.findById(req.user._id).select('-password')`; return `{ success: true, user: { id, name, email } }`
- [x] 2.5 Create `src/routes/authRoutes.js` — validation chains for register and login; `validate` helper (first error → 400); wire routes: `POST /register`, `POST /login`, `GET /me` (guarded by `protect`)

**Checkpoint 2** — must pass before Phase 3:
```
npm run lint        # zero errors across all src/
```

---

## Phase 3: Integration

- [x] 3.1 Create `src/app.js` — `express()`, `express.json()` middleware, mount `authRoutes` at `/api/auth`, export app
- [x] 3.2 Create `server.js` — `require('dotenv').config()`, import `app` and `connectDB`, call `connectDB()`, `app.listen(PORT)`
- [x] 3.3 Smoke-start server: `node server.js` — confirm log lines "MongoDB connected" and "Server running on 5000"
- [x] 3.4 Smoke-test register: `POST /api/auth/register` with `{name, email, password}` → expect `{ success: true, token, user }`
- [x] 3.5 Smoke-test login: `POST /api/auth/login` → expect `{ success: true, token, user }`
- [x] 3.6 Smoke-test protected route: `GET /api/auth/me` with `Authorization: Bearer <token>` → expect `{ success: true, user }`

**Checkpoint 3** — must pass before Phase 4:
```
npm run lint        # zero errors
npm test            # passes (--passWithNoTests, suite empty at this point)
node server.js      # starts without errors
```

---

## Phase 4: Tests

> One test per spec scenario. All tests live in `src/__tests__/auth.test.js`.
> Use `supertest` + `mongodb-memory-server` for isolated, real-DB integration tests.

- [x] 4.0 Create `src/__tests__/auth.test.js` — `beforeAll` starts in-memory MongoDB + connects Mongoose; `afterAll` disconnects; `afterEach` clears `users` collection

**user-auth · Registration scenarios**

- [x] 4.1 [spec: Successful registration] POST `/api/auth/register` with valid body → 200, `success: true`, `token` present, `user` has `id/name/email`, no `password` field
- [x] 4.2 [spec: Duplicate email] Register same email twice → second call returns 409, `message: "Email already registered"`
- [x] 4.3 [spec: Missing required field — name] POST without `name` → 400, `success: false`, message contains "required"
- [x] 4.4 [spec: Missing required field — email] POST without `email` → 400, `success: false`
- [x] 4.5 [spec: Missing required field — password] POST without `password` → 400, `success: false`
- [x] 4.6 [spec: Invalid email format] POST with `email: "not-an-email"` → 400, `message: "Valid email is required"`
- [x] 4.7 [spec: Password too short] POST with `password: "abc"` (< 6 chars) → 400, `message: "Password must be at least 6 characters"`

**user-auth · Login scenarios**

- [x] 4.8 [spec: Successful login] Register then login with same credentials → 200, `success: true`, `token` present, `user` has `id/name/email`
- [x] 4.9 [spec: Unknown email] POST `/api/auth/login` with unregistered email → 401, `message: "Invalid credentials"`
- [x] 4.10 [spec: Wrong password] Login with correct email + wrong password → 401, `message: "Invalid credentials"`
- [x] 4.11 [spec: Missing credentials] POST `/api/auth/login` without `email` or `password` → 400, `success: false`

**user-auth · Profile scenarios**

- [x] 4.12 [spec: Authenticated /me] Register, use returned token on `GET /api/auth/me` → 200, `{ success: true, user: { id, name, email } }`, no `password` field
- [x] 4.13 [spec: Unauthenticated /me] `GET /api/auth/me` with no header → 401, `success: false`

**auth-middleware · JWT verification scenarios**

- [x] 4.14 [spec: Malformed Bearer token] `GET /api/auth/me` with `Authorization: Bearer INVALID` → 401, `message: "Not authorized, token failed"`
- [x] 4.15 [spec: Expired token] Sign a token with `expiresIn: '1ms'`, wait 5ms, call `GET /api/auth/me` → 401, `message: "Not authorized, token failed"`

**Checkpoint 4** — final gate:
```
npm run lint        # zero errors
npm test            # 15/15 tests green, zero failures
node server.js      # still starts cleanly after test teardown
```

---

## Notes

- `mongodb-memory-server` spins up a real in-memory Mongo instance — no mocking, no external DB dependency in CI.
- Tasks 2.1–2.4 can be opened in parallel tabs/agents; they write to different exports within `authController.js` or separate files.
- The `.env` file must be populated before tasks 3.3–3.6 and is never committed (`.gitignore` task 1.4).
- Do not mark any phase complete if its checkpoint command fails.
