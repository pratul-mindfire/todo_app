import Foundation
import Combine

// MARK: - TaskFormViewModel

final class TaskFormViewModel: ObservableObject {

    // MARK: Form Fields

    @Published var title: String      = ""
    @Published var description: String = ""
    @Published var priority: Priority  = .medium
    @Published var hasDueDate: Bool    = false
    @Published var dueDate: Date       = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()

    // MARK: Validation

    @Published var validationError: String? = nil

    // MARK: Editing Context

    private(set) var existingTask: Task?
    var isEditing: Bool { existingTask != nil }

    // MARK: Init

    init(task: Task? = nil) {
        self.existingTask = task
        if let task = task {
            title       = task.title
            description = task.description ?? ""
            priority    = task.priority
            if let due = task.dueDate {
                hasDueDate = true
                dueDate    = due
            }
        }
    }

    // MARK: Validation

    @discardableResult
    func validate() -> Bool {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            validationError = "Title is required."
            return false
        }
        validationError = nil
        return true
    }

    // MARK: Build Task

    func buildTask() -> Task {
        var task       = existingTask ?? Task(title: "", priority: .medium)
        task.title       = title.trimmingCharacters(in: .whitespacesAndNewlines)
        task.description = description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? nil
                            : description.trimmingCharacters(in: .whitespacesAndNewlines)
        task.priority    = priority
        task.dueDate     = hasDueDate ? dueDate : nil
        return task
    }
}
