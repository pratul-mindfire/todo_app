import SwiftUI

// MARK: - TaskDetailView

struct TaskDetailView: View {

    let task: Task
    @ObservedObject var listViewModel: TaskListViewModel

    @State private var showEditSheet    = false
    @State private var showDeleteAlert  = false
    @Environment(\.presentationMode) private var presentationMode

    /// Always reads from the live task list so edits are reflected immediately
    private var current: Task {
        listViewModel.tasks.first { $0.id == task.id } ?? task
    }

    // MARK: Body

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerCard
                detailsCard
                Spacer(minLength: 40)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Task Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { menuButton }
        .sheet(isPresented: $showEditSheet) {
            TaskFormView(
                viewModel: TaskFormViewModel(task: current),
                listViewModel: listViewModel
            )
        }
        .alert("Delete Task", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                listViewModel.delete(task: current)
                presentationMode.wrappedValue.dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete "\(current.title)"? This cannot be undone.")
        }
    }

    // MARK: Header Card

    private var headerCard: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(current.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .strikethrough(current.isCompleted)
                    .foregroundColor(current.isCompleted ? .secondary : .primary)

                priorityBadge(current.priority)
            }
            Spacer()
            Button(action: { listViewModel.toggleComplete(task: current) }) {
                Image(systemName: current.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 30))
                    .foregroundColor(current.isCompleted ? .green : Color(.tertiaryLabel))
                    .animation(.easeInOut(duration: 0.2), value: current.isCompleted)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }

    // MARK: Details Card

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let desc = current.description, !desc.isEmpty {
                detailRow(icon: "text.alignleft",   label: "Description", value: desc)
                Divider()
            }
            if let due = current.dueDate {
                detailRow(icon: "calendar",          label: "Due Date",    value: mediumDate(due))
                Divider()
            }
            detailRow(icon: "clock",                 label: "Created",     value: mediumDate(current.createdAt))
            Divider()
            detailRow(
                icon:  current.isCompleted ? "checkmark.circle" : "circle.dotted",
                label: "Status",
                value: current.isCompleted ? "Completed ✓" : "Pending"
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var menuButton: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Button { showEditSheet = true } label: {
                    Label("Edit", systemImage: "pencil")
                }
                Button(role: .destructive) { showDeleteAlert = true } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    // MARK: Sub-views

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func priorityBadge(_ priority: Priority) -> some View {
        let color: Color = priority == .high ? .red : priority == .medium ? .orange : .green
        return Text(priority.rawValue)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    // MARK: Helpers

    private func mediumDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }
}
