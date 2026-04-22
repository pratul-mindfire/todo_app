## Phase 1: Foundation — Environment Config

> Sequential. Must complete before any code change so the app can read `API_VERSION` at startup.

- [x] 1.1 Add `API_VERSION=v1` to `.env`
- [x] 1.2 Add `API_VERSION=v1` to Vercel environment variables (`npx vercel env add API_VERSION` → enter `v1`)

**Checkpoint 1:**
```
npm run lint        # zero errors (no code changed yet — should be instant pass)
```

---

## Phase 2: Core Implementation

> 2 lines in one file. No parallel work needed.

- [x] 2.1 In `src/app.js`, add `const API_VERSION = process.env.API_VERSION || 'v1';` after the `require` statements
- [x] 2.2 In `src/app.js`, add `app.use(\`/api/${API_VERSION}/auth\`, authRoutes);` above the existing `/api/auth` mount
- [x] 2.3 Confirm the existing `app.use('/api/auth', authRoutes);` line is unchanged (backward-compat mount stays in place)

**Checkpoint 2:**
```
npm run lint        # zero errors across src/ and server.js
```

---

## Phase 3: Integration

- [x] 3.1 Start server: `node server.js` — confirm logs "MongoDB connected" and "Server running on 5000"
- [x] 3.2 Smoke-test versioned path: `POST /api/v1/auth/register` with valid body → expect `{ success: true, token, user }`
- [x] 3.3 Smoke-test backward-compat path: `POST /api/auth/register` with valid body → expect same `{ success: true, token, user }`
- [x] 3.4 Stop server after confirming both paths respond correctly

**Checkpoint 3:**
```
npm run lint        # zero errors
npm test            # existing 15/15 still green (no test changes yet)
```

---

## Phase 4: Tests

> One test per spec scenario from `specs/api-versioning/spec.md`. Add `process.env.API_VERSION = 'v1'` to `beforeAll`, then append a new `describe` block.

- [x] 4.0 In `src/__tests__/auth.test.js` `beforeAll`, add `process.env.API_VERSION = 'v1';` alongside the existing `JWT_SECRET` assignment

**api-versioning · Versioned path scenarios**

- [x] 4.1 [spec: Versioned path is reachable — register] POST `/api/v1/auth/register` with valid body → 200, `success: true`, `token` present
- [x] 4.2 [spec: Versioned path is reachable — login] Register via versioned path, then POST `/api/v1/auth/login` → 200, `success: true`, `token` present
- [x] 4.3 [spec: Versioned path is reachable — me] Register via versioned path, GET `/api/v1/auth/me` with token → 200, `success: true`, `user` present

**api-versioning · Backward-compat unversioned path scenarios**

- [x] 4.4 [spec: Unversioned register still works] POST `/api/auth/register` with valid body → 200, `success: true`
- [x] 4.5 [spec: Unversioned login still works] Register, then POST `/api/auth/login` → 200, `success: true`
- [x] 4.6 [spec: Unversioned me still works] Register, GET `/api/auth/me` with token → 200, `success: true`

**Checkpoint 4 — final gate:**
```
npm run lint        # zero errors
npm test            # 21/21 tests green (15 existing + 6 new), zero failures
node server.js      # still starts cleanly
```

---

## Notes

- All new tests go in `src/__tests__/auth.test.js` as two new `describe` blocks appended after the existing ones.
- The `afterEach` collection wipe already covers the new test blocks — no setup changes needed beyond task 4.0.
- Vercel redeploy (task 1.2) should be done after the code changes are deployed so the env var is live before the function picks it up.
- Do not mark any phase complete if its checkpoint fails.
