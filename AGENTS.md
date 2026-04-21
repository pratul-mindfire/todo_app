# 🤖 AGENTS.md — iOS Todo App (SwiftUI)

## 1. Overview

This document defines AI agents, responsibilities, and workflows for building the **iOS Todo App** using **spec-driven development**.

Agents must:
- Follow `spec.md` strictly
- Avoid inventing requirements
- Keep code modular, testable, and SwiftUI-native

---

## 2. Global Rules

- Use **SwiftUI + MVVM**
- Target **iOS 17+**
- Prefer **async/await**
- No business logic inside Views
- All state lives in ViewModels
- Use dependency injection for services
- Keep files small and focused

---

## 3. Agents

### 🧠 3.1 Planner Agent

**Purpose:**  
Translates `spec.md` into implementation steps.

**Responsibilities:**
- Break features into tasks
- Define file structure
- Identify dependencies
- Clarify ambiguities

**Output:**
- Task list
- File/module plan

---

### 🏗️ 3.2 Architect Agent

**Purpose:**  
Designs app structure and contracts.

**Responsibilities:**
- Define models
- Define ViewModel interfaces
- Define service protocols
- Enforce MVVM boundaries

**Rules:**
- No UI code
- Focus on abstractions

---

### 💻 3.3 Implementation Agent

**Purpose:**  
Writes SwiftUI and Swift code.

**Responsibilities:**
- Implement Views
- Implement ViewModels
- Implement Services
- Follow architecture strictly

**Rules:**
- Views = UI only
- ViewModels = logic + state
- Services = data fetching/storage

---

### 🎨 3.4 UI Agent

**Purpose:**  
Refines UI/UX.

**Responsibilities:**
- Improve layout
- Ensure consistency
- Add animations (minimal, meaningful)
- Support Dark Mode

---

### 🧪 3.5 Testing Agent

**Purpose:**  
Ensures correctness.

**Responsibilities:**
- Write unit tests for ViewModels
- Mock services
- Validate edge cases

---

### 🔍 3.6 Review Agent

**Purpose:**  
Maintains code quality.

**Responsibilities:**
- Check architecture compliance
- Detect duplication
- Ensure readability
- Validate against `spec.md`

---

## 4. App Scope (Todo App)

### Core Features

- Add Todo
- Edit Todo
- Delete Todo
- Mark as Complete
- Persist Todos (local storage)

---

## 5. Data Model

```swift
struct Todo: Identifiable, Codable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var createdAt: Date
}