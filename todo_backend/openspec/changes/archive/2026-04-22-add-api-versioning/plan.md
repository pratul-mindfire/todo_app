# Implementation Plan — add-api-versioning

> Status: **PENDING APPROVAL** — do not implement until approved.

---

## 1. Scope Summary

This is a minimal, surgical change. The entire implementation is:
- **2 lines added** to `src/app.js`
- **1 line added** to `.env`
- **6 new tests + 1 setup line** added to `src/__tests__/auth.test.js`

No new files. No new dependencies. No controller, middleware, model, or route changes.

---

## 2. Files to Modify

| File | Change type | Summary |
|---|---|---|
| `src/app.js` | Modify | Add `API_VERSION` constant + second versioned mount |
| `.env` | Modify | Add `API_VERSION=v1` |
| `src/__tests__/auth.test.js` | Modify | Set `API_VERSION` in `beforeAll`; add 6 new tests |

**No other files change.** `server.js`, `api/index.js` (Vercel), all controllers, routes, middleware, models — untouched.

---

## 3. Exact Diffs

### `src/app.js` — current state (8 lines)

```js
const express = require('express');
const authRoutes = require('./routes/authRoutes');

const app = express();

app.use(express.json());
app.use('/api/auth', authRoutes);

module.exports = app;
```

### `src/app.js` — after change

```js
const express = require('express');
const authRoutes = require('./routes/authRoutes');

const app = express();
const API_VERSION = process.env.API_VERSION || 'v1';

app.use(express.json());
app.use(`/api/${API_VERSION}/auth`, authRoutes);
app.use('/api/auth', authRoutes);

module.exports = app;
```

**Lines added:** 2 (`const API_VERSION` + versioned `app.use`).
**Lines changed:** 0 (existing mount stays exactly as-is).

---

### `.env` — add one line

```diff
  PORT=5000
  MONGO_URI=mongodb+srv://...
  JWT_SECRET=your_jwt_secret_here
+ API_VERSION=v1
```

> Also add `API_VERSION=v1` to Vercel environment variables so the deployed function picks it up.

---

### `src/__tests__/auth.test.js` — additions only

**In `beforeAll`**, add one line:
```js
process.env.API_VERSION = 'v1';
```

**Append a new `describe` block** after the existing tests:

```js
// ---------------------------------------------------------------------------
// API versioning scenarios
// ---------------------------------------------------------------------------

describe('API versioning — versioned paths (/api/v1/auth/*)', () => {
  it('V.1 versioned register path returns 200', async () => {
    const res = await request(app).post('/api/v1/auth/register').send(validUser);
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.token).toBeDefined();
  });

  it('V.2 versioned login path returns 200', async () => {
    await request(app).post('/api/v1/auth/register').send(validUser);
    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: validUser.email, password: validUser.password });
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.token).toBeDefined();
  });

  it('V.3 versioned /me path returns 200 with valid token', async () => {
    const reg = await request(app).post('/api/v1/auth/register').send(validUser);
    const res = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${reg.body.token}`);
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });
});

describe('API versioning — backward-compat unversioned paths (/api/auth/*)', () => {
  it('V.4 unversioned register still returns 200', async () => {
    const res = await request(app).post('/api/auth/register').send(validUser);
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });

  it('V.5 unversioned login still returns 200', async () => {
    await request(app).post('/api/auth/register').send(validUser);
    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: validUser.email, password: validUser.password });
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });

  it('V.6 unversioned /me still returns 200 with valid token', async () => {
    const reg = await request(app).post('/api/auth/register').send(validUser);
    const res = await request(app)
      .get('/api/auth/me')
      .set('Authorization', `Bearer ${reg.body.token}`);
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });
});
```

---

## 4. Architecture Decisions

| Decision | Choice | Reason |
|---|---|---|
| Implementation approach | Dual-mount in `src/app.js` | Same router at two prefixes — zero overhead, no redirect latency, no code duplication |
| Backward compat | Keep `/api/auth/*` alive | Existing smoke tests, Vercel deployment, and any manual testers continue to work |
| Version source | `process.env.API_VERSION \|\| 'v1'` | Env-var-driven as requested; `\|\| 'v1'` prevents crash if var is missing in dev |
| Scope of change | Only mount point in `src/app.js` | No router/controller/middleware changes — lowest blast radius possible |
| Order of mounts | Versioned first, then unversioned | Express matches in order; versioned path is canonical; unversioned is the fallback compat layer |

---

## 5. Database Changes

None. This change is purely routing — no schema changes, no migrations, no new collections.

---

## 6. Reuse of Existing Code

Everything is reused as-is:
- `authRoutes` router instance — mounted twice, shared reference
- All controllers (`registerUser`, `loginUser`, `getMe`) — unchanged
- Auth middleware (`protect`) — unchanged
- All existing 15 tests — unchanged; they test the unversioned paths which remain valid

---

## 7. Quality Gate Commands

```bash
# After editing src/app.js and .env:
npm run lint              # must exit 0

# After adding tests:
npm test                  # must show 21/21 passed (15 existing + 6 new)

# Smoke check (requires populated .env with MONGO_URI + JWT_SECRET + API_VERSION):
node server.js            # must log "MongoDB connected" + "Server running on 5000"

# Verify versioned path:
curl -s -X POST http://localhost:5000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","email":"v1@example.com","password":"secret123"}' | jq .

# Verify backward-compat:
curl -s -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test2","email":"compat@example.com","password":"secret123"}' | jq .
```

---

## 8. Vercel Deployment Note

After merging, add `API_VERSION=v1` to Vercel environment variables before redeploying:

```bash
npx vercel env add API_VERSION
# enter: v1
npx vercel --prod
```

`api/index.js` requires `src/app.js`, which reads `process.env.API_VERSION` at require-time. Vercel injects env vars before the function module is loaded, so the versioned mount will be active on the deployed function.

---

## 9. Out of Scope

- Multi-version routing (v1 + v2 simultaneously)
- `Deprecation` header on unversioned paths
- Startup validation of `API_VERSION` format (nice-to-have, not required)
- Any changes outside `src/app.js` and the test file

---

## Approval Required

Do not begin implementation until this plan is approved. Once approved, run `/implement add-api-versioning` or `/opsx:apply`.
