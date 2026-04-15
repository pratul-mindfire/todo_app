import Foundation
import Combine

// MARK: - Filter / Sort Enums

enum TaskFilter: String, CaseIterable {
    case all       = "All"
    case pending   = "Pending"
    case completed = "Completed"
}

enum TaskSort: String, CaseIterable {
    case createdAt = "Created"
    case dueDate   = "Due Date"
    case priority  = "Priority"
}

// MARK: - TaskListViewModel

final class TaskListViewModel: ObservableObject {

    // MARK: Published State

    @Published var tasks: [Task]          = []
    @Published var filter: TaskFilter     = .all
    @Published var sort: TaskSort         = .createdAt
    @Published var priorityFilter: Priority? = nil

    // MARK: Dependencies

    private let repository: TaskRepository
    private let notifications = NotificationService.shared

    // MARK: Init

    init(repository: TaskRepository = JSONTaskRepository()) {
        self.repository = repository
        loadTasks()
    }

    // MARK: Data Loading

    func loadTasks() {
        tasks = repository.getAllTasks()
    }

    // MARK: Computed Groups (used by the list view)

    /// Tasks due today (not completed)
    var todayTasks: [Task] {
        filteredSorted.filter {
            guard let due = $0.dueDate else { return false }
            return Calendar.current.isDateInToday(due) && !$0.isCompleted
        }
    }

    /// Tasks with a future due date (not today, not completed)
    var upcomingTasks: [Task] {
        filteredSorted.filter {
            guard let due = $0.dueDate else { return false }
            return due > Date() && !Calendar.current.isDateInToday(due) && !$0.isCompleted
        }
    }

    /// Pending tasks without a due date
    var noDueDateTasks: [Task] {
        filteredSorted.filter { $0.dueDate == nil && !$0.isCompleted }
    }

    /// Completed tasks (any due-date scenario)
    var completedTasks: [Task] {
        filteredSorted.filter { $0.isCompleted }
    }

    // MARK: Task Operations

    func toggleComplete(task: Task) {
        var updated         = task
        updated.isCompleted.toggle()
        repository.update(task: updated)

        if updated.isCompleted {
            notifications.cancelNotification(for: updated)
        } else {
            notifications.scheduleNotification(for: updated)
        }
        loadTasks()
    }

    func addTask(_ task: Task) {
        repository.save(task: task)
        notifications.scheduleNotification(for: task)
        loadTasks()
    }

    func updateTask(_ task: Task) {
        repository.update(task: task)
        notifications.cancelNotification(for: task)
        notifications.scheduleNotification(for: task)
        loadTasks()
    }

    func delete(task: Task) {
        notifications.cancelNotification(for: task)
        repository.delete(task: task)
        loadTasks()
    }

    // MARK: Private Helpers

    private var filteredSorted: [Task] {
        var result = tasks

        // --- Status filter ---
        switch filter {
        case .pending:   result = result.filter { !$0.isCompleted }
        case .completed: result = result.filter {  $0.isCompleted }
        case .all:       break
        }

        // --- Priority filter ---
        if let pf = priorityFilter {
            result = result.filter { $0.priority == pf }
        }

        // --- Sort ---
        switch sort {
        case .dueDate:
            result.sort { a, b in
                switch (a.dueDate, b.dueDate) {
                case let (d1?, d2?): return d1 < d2
                case (nil, _?):      return false
                case (_?, nil):      return true
                default:             return a.createdAt < b.createdAt
                }
            }
        case .priority:
            result.sort { $0.priority < $1.priority }
        case .createdAt:
            result.sort { $0.createdAt < $1.createdAt }
        }

        return result
    }
}
