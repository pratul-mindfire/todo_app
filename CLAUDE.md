@AGENTS.md
# Claude Code — iOS Swift Project Rules

---

## Permission Model

**Proceed without asking:**

* Reading any Swift, Xcode, or config file (`.swift`, `.plist`, `.xcconfig`)
* Running builds and tests via Xcode CLI
* Editing SwiftUI views, ViewModels, models, and services
* Resolving Swift Package Manager dependencies (`swift package resolve`)
* Running formatters and linters (e.g., SwiftLint)

**Always ask [y/n] before:**

* `git push` (any remote write)
* `git reset --hard` / `git clean -fd`
* Deleting files (`rm`, `rmdir`)
* Modifying provisioning profiles, certificates, or signing settings
* Changing bundle identifiers or app capabilities
* Running scripts that affect CI/CD or App Store deployment

---

## Context Management

* Clear context (`/clear`) when token usage approaches **60k**
* Before clearing:

  * Summarise current features, bugs, and pending tasks
* Always carry forward:

  * Architecture decisions (MVVM, persistence choice, etc.)
* Never let multi-step feature work span contexts without a handoff summary

---

## Thinking Depth

| Situation                           | Depth                       |
| ----------------------------------- | --------------------------- |
| UI text change / minor Swift fix    | None — act immediately      |
| Single View / ViewModel change      | Brief inline reasoning      |
| Multi-screen flow change            | Outline plan, confirm once  |
| Architecture / persistence decision | Full reasoning + trade-offs |

---

## Project Architecture Rules

* Follow **MVVM (Model-View-ViewModel)**
* Use **SwiftUI** for UI
* Prefer **async/await** over callbacks
* Use **Combine** only when necessary
* Keep business logic out of Views
* Use Repository pattern for data access

---

## Folder Structure (expected)

```
/App
  /Models
  /ViewModels
  /Views
  /Services
  /Repositories
  /Utilities
```

---

## Code Style Guidelines

* Follow Swift naming conventions (camelCase)
* Prefer structs over classes unless reference semantics needed
* Use `@StateObject` for ViewModel ownership
* Use `@ObservedObject` for injected dependencies
* Keep Views declarative and minimal
* Avoid force unwraps (`!`)

---

## Commit Message Format

```
<type>(<scope>): <short imperative summary>

- bullet detail if needed
- Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```

**Types:** `feat` · `fix` · `refactor` · `test` · `chore` · `docs`
**Scope examples:** `view`, `viewmodel`, `repository`, `network`, `notification`

Example:

```
feat(viewmodel): add task filtering by priority
```

---

## Branch Naming

```
<type>/<short-kebab-description>
```

Examples:

* `feat/add-task-form`
* `fix/crash-on-empty-title`
* `refactor/repository-layer`

---

## Quality Gates (run in order)

1. **Lint**

   ```
   swiftlint
   ```

2. **Tests**

   ```
   xcodebuild test -scheme TodoApp
   ```

3. **Build**

   ```
   xcodebuild build -scheme TodoApp
   ```

* Stop immediately on failure
* Fix issues before proceeding
* Never bypass checks (`--no-verify` not allowed)

---

## Testing Guidelines

* Write unit tests for:

  * ViewModels
  * Business logic
* Mock repositories/services
* Avoid UI testing unless necessary

---

## Navigation Rules

* Use `NavigationStack` (modern SwiftUI)
* Avoid hardcoded navigation logic inside Views
* Centralize navigation flow when possible

---

## State Management

* Use:

  * `@State`
  * `@StateObject`
  * `@ObservedObject`
* Keep state minimal and localized
* Avoid global mutable state

---

## Data Persistence Rules

* Use abstraction:

  * `TaskRepository` protocol
* Allow easy swap:

  * Core Data → API (future)
* Do not tightly couple UI to storage layer

---

## Notifications

* Use local notifications via `UNUserNotificationCenter`
* Ensure:

  * Permission handling
  * Cancellation on task deletion

---

## Commands Requiring [y/n]

| Command                        | Reason                  |
| ------------------------------ | ----------------------- |
| `git push [--force]`           | Remote state change     |
| `git reset --hard`             | Irreversible local loss |
| `git clean -fd`                | Deletes untracked files |
| `rm` / `rmdir`                 | File deletion           |
| Signing / provisioning changes | Can break builds        |
| App Store / TestFlight configs | Deployment impact       |

---

## Definition of Done

A task is complete only if:

* Code builds successfully in Xcode
* All tests pass
* Lint passes
* Feature matches FRS/SDS
* No runtime crashes
* Code follows MVVM and project rules

---
