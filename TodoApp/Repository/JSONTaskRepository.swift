import Foundation

// MARK: - JSON File-Based Repository (MVP Implementation)

final class JSONTaskRepository: TaskRepository {

    // MARK: Private

    private let fileName = "tasks.json"
    private let encoder  = JSONEncoder()
    private let decoder  = JSONDecoder()

    private var fileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent(fileName)
    }

    // MARK: TaskRepository

    func getAllTasks() -> [Task] {
        guard
            let data  = try? Data(contentsOf: fileURL),
            let tasks = try? decoder.decode([Task].self, from: data)
        else { return [] }
        return tasks
    }

    func save(task: Task) {
        var tasks = getAllTasks()
        tasks.append(task)
        persist(tasks)
    }

    func update(task: Task) {
        var tasks = getAllTasks()
        guard let idx = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[idx] = task
        persist(tasks)
    }

    func delete(task: Task) {
        var tasks = getAllTasks()
        tasks.removeAll { $0.id == task.id }
        persist(tasks)
    }

    // MARK: Private Helpers

    private func persist(_ tasks: [Task]) {
        guard let data = try? encoder.encode(tasks) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
