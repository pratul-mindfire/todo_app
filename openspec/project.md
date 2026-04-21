# Project Context — iOS To-Do Application

## Product Summary

A personal task manager for a single iOS user. No authentication in v1.
Users create, organize, and track tasks with local persistence and reminder notifications.

---

## Tech Stack

| Concern | Choice |
|---|---|
| Language | Swift (native only, no third-party packages) |
| UI | SwiftUI — declarative, no UIKit |
| Architecture | MVVM |
| Concurrency | async/await (preferred); Combine only for reactive streams |
| Persistence | Repository pattern — JSON file-based for MVP |
| Notifications | UNUserNotificationCenter (local only) |
| Minimum Target | iOS 17+ |

---

## Domain Model

```swift
struct Task: Identifiable, Codable {
    var id: UUID
    var title: String          // required
    var description: String?
    var dueDate: Date?
    var priority: Priority     // .low | .medium | .high
    var isCompleted: Bool
    var createdAt: Date
}

enum Priority: String, Codable { case low, medium, high }
```

Repository contract:

```swift
protocol TaskRepository {
    func getAllTasks() -> [Task]
    func save(task: Task)
    func delete(task: Task)
}
```

Concrete implementation: `JSONTaskRepository` (Documents directory, file-based).
Abstraction allows a future swap to Core Data or a remote API without touching the UI layer.

---

## Architectural Constraints

- **MVVM is strict**: business logic lives in ViewModels, never in Views.
- Views are declarative and minimal — no data fetching or transformation.
- `@StateObject` for ViewModel ownership; `@ObservedObject` for injected dependencies.
- Repository pattern is the only way Views/ViewModels touch storage.
- No force-unwraps (`!`); no global mutable state.
- Prefer structs over classes unless reference semantics are required.
- `NavigationStack` for all navigation (no `NavigationView`).

### Layer responsibilities

| Layer | Owns |
|---|---|
| Model | Data shape, Codable, no logic |
| ViewModel | State, filtering, sorting, validation, repository calls |
| View | Rendering, user input forwarding |
| Repository | Read/write persistence |
| Service | Notification scheduling/cancellation |

---

## Folder Structure

```
TodoApp/
  Models/
  ViewModels/
  Views/
  Repository/
  Services/
```

---

## Screens & Navigation

```
TaskListView
  ├── → TaskDetailView
  │       └── → TaskFormView  (edit)
  └── → TaskFormView          (add)
```

### ViewModels in scope

- `TaskListViewModel` — fetch, filter, sort, delete, toggle completion
- `TaskFormViewModel` — input validation, create / update

---

## Functional Scope (v1)

| ID | Requirement |
|---|---|
| FR-1 | Create task: title (required), description, dueDate, priority (optional) |
| FR-2 | View tasks grouped: Today / Upcoming / Completed |
| FR-3 | Edit all task fields |
| FR-4 | Delete task with confirmation prompt |
| FR-5 | Toggle completion status |
| FR-6 | Filter by status (pending / completed) and priority |
| FR-7 | Sort by due date, priority, or creation date |
| FR-8 | Local reminder notification at dueDate; cancel on deletion |
| FR-9 | Persist tasks across restarts; no data loss on crash |

**Out of scope (v1):** cloud sync, authentication, collaboration, widgets, CloudKit, background refresh.

---

## Team Conventions

### Commit format

```
<type>(<scope>): <imperative summary>

- Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```

Types: `feat` · `fix` · `refactor` · `test` · `chore` · `docs`  
Scopes: `view` · `viewmodel` · `repository` · `service` · `notification`

### Branch naming

```
<type>/<short-kebab-description>
```

Examples: `feat/add-task-form`, `fix/crash-on-empty-title`

### Code style

- camelCase for variables/functions; PascalCase for types/enums
- Avoid `!`; avoid `class` unless reference semantics are required
- Keep files small and focused (one type per file)

---

## Quality Standards

Gates run in order — stop immediately on failure:

1. **Lint** — `swiftlint` must pass
2. **Tests** — `xcodebuild test -scheme TodoApp` — all green
3. **Build** — `xcodebuild build -scheme TodoApp` — clean build

Never bypass with `--no-verify` or equivalent.

**Definition of done:** builds + tests pass + lint clean + feature matches FRS + no runtime crashes + MVVM rules followed.

### Testing guidelines

- Unit tests required for every ViewModel
- Mock repositories/services in tests
- No UI tests unless explicitly requested

---

## Non-Functional Requirements

- App launch < 2 seconds; task operations < 500 ms
- Dark Mode support
- Minimal taps for task creation
- Local data must survive app crashes (atomic writes)
