import SwiftUI

// MARK: - App Entry Point

@main
struct TodoApp: App {
    var body: some Scene {
        WindowGroup {
            TaskListView()
        }
    }
}
