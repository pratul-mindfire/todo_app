# Software Design Specification (SDS)

## Project: iOS To-Do Application

---

## 1. Overview

### 1.1 Architecture

* Pattern: MVVM (Model-View-ViewModel)
* UI Framework: SwiftUI
* Data Persistence: Core Data / SQLite
* Concurrency: Combine / async-await

---

## 2. System Architecture

### 2.1 High-Level Components

* Presentation Layer (SwiftUI Views)
* ViewModel Layer (State Management)
* Data Layer (Persistence + Repository)
* Services Layer (Notifications)

---

## 3. Module Design

### 3.1 Models

#### Task Model

```swift
struct Task: Identifiable, Codable {
    var id: UUID
    var title: String
    var description: String?
    var dueDate: Date?
    var priority: Priority
    var isCompleted: Bool
    var createdAt: Date
}
```

#### Priority Enum

```swift
enum Priority: String, Codable {
    case low
    case medium
    case high
}
```

---

### 3.2 ViewModels

#### TaskListViewModel

* Responsibilities:

  * Fetch tasks
  * Apply filters/sorting
  * Handle delete & toggle completion

#### TaskDetailViewModel

* Responsibilities:

  * Provide task details
  * Handle updates

#### TaskFormViewModel

* Responsibilities:

  * Validate input
  * Create/update task

---

### 3.3 Views (SwiftUI)

* TaskListView
* TaskRowView
* TaskDetailView
* TaskFormView

---

### 3.4 Data Layer

#### Repository Pattern

```swift
protocol TaskRepository {
    func getAllTasks() -> [Task]
    func save(task: Task)
    func delete(task: Task)
}
```

#### Implementation Options:

* Core Data
* SQLite
* File-based JSON (for MVP)

---

### 3.5 Services

#### NotificationService

* Schedule local notifications
* Cancel notifications on task delete

---

## 4. Data Flow

1. User interacts with View
2. View triggers ViewModel
3. ViewModel calls Repository
4. Repository interacts with database
5. Data flows back to UI via state updates

---

## 5. Navigation

* TaskListView → TaskDetailView
* TaskListView → TaskFormView (Add)
* TaskDetailView → TaskFormView (Edit)

---

## 6. State Management

* Use @State, @StateObject, @ObservedObject
* Combine / async-await for async updates

---

## 7. Error Handling

* Input validation errors
* Data persistence errors
* Notification scheduling failures

---

## 8. Dependencies

* Native Apple frameworks only
* Optional:

  * Combine
  * Core Data

---

## 9. Scalability Considerations

* Abstract repository for future backend integration
* Modular architecture for feature expansion

---

## 10. Future Improvements

* CloudKit integration
* Offline-first sync engine
* Background refresh
* WidgetKit support

---
