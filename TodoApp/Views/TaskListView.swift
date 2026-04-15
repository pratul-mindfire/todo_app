import SwiftUI

// MARK: - TaskListView (Root Screen)

struct TaskListView: View {

    @StateObject private var viewModel    = TaskListViewModel()
    @State private var showAddTask        = false
    @State private var showFilterSheet    = false

    // MARK: Body

    var body: some View {
        NavigationView {
            Group {
                if viewModel.tasks.isEmpty {
                    emptyStateView
                } else {
                    taskListContent
                }
            }
            .navigationTitle("My Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    filterButton
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    addButton
                }
            }
            // Add Task Sheet
            .sheet(isPresented: $showAddTask, onDismiss: { viewModel.loadTasks() }) {
                TaskFormView(
                    viewModel: TaskFormViewModel(),
                    listViewModel: viewModel
                )
            }
            // Filter / Sort Sheet
            .sheet(isPresented: $showFilterSheet) {
                FilterSortView(viewModel: viewModel)
            }
        }
        .onAppear {
            NotificationService.shared.requestPermission()
            viewModel.loadTasks()
        }
    }

    // MARK: Toolbar Items

    private var addButton: some View {
        Button { showAddTask = true } label: {
            Image(systemName: "plus")
                .fontWeight(.semibold)
        }
    }

    private var filterButton: some View {
        Button { showFilterSheet = true } label: {
            Image(systemName: activeFilters
                  ? "line.3.horizontal.decrease.circle.fill"
                  : "line.3.horizontal.decrease.circle")
        }
        .foregroundColor(activeFilters ? .accentColor : .primary)
    }

    private var activeFilters: Bool {
        viewModel.filter != .all || viewModel.priorityFilter != nil || viewModel.sort != .createdAt
    }

    // MARK: Task List

    private var taskListContent: some View {
        List {
            todaySection
            upcomingSection
            noDueDateSection
            completedSection
        }
        .listStyle(.insetGrouped)
        .animation(.default, value: viewModel.tasks)
    }

    @ViewBuilder
    private var todaySection: some View {
        if !viewModel.todayTasks.isEmpty {
            Section {
                ForEach(viewModel.todayTasks) { task in
                    taskRow(task)
                }
            } header: {
                sectionHeader("Today", icon: "sun.max.fill", color: .orange)
            }
        }
    }

    @ViewBuilder
    private var upcomingSection: some View {
        if !viewModel.upcomingTasks.isEmpty {
            Section {
                ForEach(viewModel.upcomingTasks) { task in
                    taskRow(task)
                }
            } header: {
                sectionHeader("Upcoming", icon: "calendar", color: .blue)
            }
        }
    }

    @ViewBuilder
    private var noDueDateSection: some View {
        if !viewModel.noDueDateTasks.isEmpty {
            Section {
                ForEach(viewModel.noDueDateTasks) { task in
                    taskRow(task)
                }
            } header: {
                sectionHeader("No Due Date", icon: "tray", color: .secondary)
            }
        }
    }

    @ViewBuilder
    private var completedSection: some View {
        if !viewModel.completedTasks.isEmpty {
            Section {
                ForEach(viewModel.completedTasks) { task in
                    taskRow(task)
                }
            } header: {
                sectionHeader("Completed", icon: "checkmark.circle.fill", color: .green)
            }
        }
    }

    // MARK: Row Builder

    private func taskRow(_ task: Task) -> some View {
        NavigationLink(destination: TaskDetailView(task: task, listViewModel: viewModel)) {
            TaskRowView(task: task) {
                viewModel.toggleComplete(task: task)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                viewModel.delete(task: task)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                viewModel.toggleComplete(task: task)
            } label: {
                Label(
                    task.isCompleted ? "Undo" : "Done",
                    systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark"
                )
            }
            .tint(task.isCompleted ? .orange : .green)
        }
    }

    // MARK: Section Header

    private func sectionHeader(_ title: String, icon: String, color: Color) -> some View {
        Label(title, systemImage: icon)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(color)
    }

    // MARK: Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checklist")
                .font(.system(size: 72))
                .foregroundColor(Color(.tertiaryLabel))

            Text("No Tasks Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Tap  +  to create your first task")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: { showAddTask = true }) {
                Label("Create Task", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            .padding(.top, 8)
        }
        .padding()
    }
}
