# CLAUDE.md — Claude Code Rules

@AGENTS.md

Claude Code-specific rules only. Project conventions live in AGENTS.md above.

---

## Permission Model

**Proceed without asking:**
- Read any file in the repo
- Edit source files, tests, config
- Run `npm install`, `npm test`, `npm run lint`
- Run `node` or `nodemon` locally

**Always ask [y/n] before:**
- `git push` (any branch, any remote)
- `git reset --hard` or any destructive git operation
- Deleting files or directories
- Modifying `.env` or any secrets file
- Running database migration/seed scripts
- Installing new packages (`npm install <pkg>`) — confirm the package name first

---

## Context Management

- If the conversation approaches 60k tokens, stop and say: _"Context is getting large — recommend /clear before continuing."_
- After `/clear`, re-read `AGENTS.md` and any files actively being edited before resuming.
- Do not summarize prior work into the chat — use git log or re-read files instead.

---

## Thinking Depth

- **Simple edits** (typo, rename, single-line fix): no extended thinking needed.
- **New feature or cross-file refactor**: think through the full call chain (route → controller → model) before writing code.
- **Auth or security changes**: always reason about token flow and attack surface before editing.

---

## Commit Message Format

```
<type>(<scope>): <short imperative summary>

[optional body — one paragraph max, explain WHY not WHAT]
```

Types: `feat`, `fix`, `refactor`, `test`, `chore`, `docs`
Scope: `auth`, `user`, `middleware`, `config`, `utils`

Example: `feat(auth): add JWT login endpoint`

- Subject line: 72 chars max, no period at end
- Never amend published commits; create a new one

---

## Branch Naming

```
<type>/<short-slug>
```

Examples: `feat/login-endpoint`, `fix/token-expiry`, `chore/eslint-setup`

---

## Quality Gates (run in this order)

1. `npm run lint` — must pass with zero errors
2. `npm test` — must pass with zero failures
3. `node server.js` (smoke check) — server must start without errors

Do not report a task complete if any gate fails.

---

## Commands That Need [y/n]

| Command                        | Why                          |
|--------------------------------|------------------------------|
| `git push`                     | Affects shared remote        |
| `git reset --hard`             | Irreversible local changes   |
| `rm` / file deletion           | Cannot be undone easily      |
| `npm install <new-package>`    | Changes dependency tree      |
| Any script touching `.env`     | Risk of secret exposure      |
