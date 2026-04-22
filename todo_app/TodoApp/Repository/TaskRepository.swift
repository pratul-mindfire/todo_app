import Foundation

// MARK: - Repository Protocol

/// Abstract contract for task persistence.
/// Swap implementations (JSON → Core Data → CloudKit) without touching ViewModels.
protocol TaskRepository {
    func getAllTasks() -> [Task]
    func save(task: Task)
    func update(task: Task)
    func delete(task: Task)
}
