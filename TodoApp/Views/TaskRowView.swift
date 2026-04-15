import SwiftUI

// MARK: - TaskRowView

struct TaskRowView: View {

    let task: Task
    let onToggle: () -> Void

    // MARK: Body

    var body: some View {
        HStack(alignment: .center, spacing: 12) {

            // Completion toggle button
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(task.isCompleted ? .green : Color(.tertiaryLabel))
                    .animation(.easeInOut(duration: 0.2), value: task.isCompleted)
            }
            .buttonStyle(.plain)

            // Task info
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                    .strikethrough(task.isCompleted, color: .secondary)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    priorityBadge
                    if let due = task.dueDate {
                        dueDateLabel(due)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    // MARK: Sub-views

    private var priorityBadge: some View {
        Text(task.priority.rawValue)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(priorityColor.opacity(0.15))
            .foregroundColor(priorityColor)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private func dueDateLabel(_ date: Date) -> some View {
        let overdue = date < Date() && !Calendar.current.isDateInToday(date) && !task.isCompleted
        return Label(shortDate(date), systemImage: "calendar")
            .font(.caption)
            .foregroundColor(overdue ? .red : .secondary)
    }

    // MARK: Helpers

    private var priorityColor: Color {
        switch task.priority {
        case .high:   return .red
        case .medium: return .orange
        case .low:    return .green
        }
    }

    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .short
        return f.string(from: date)
    }
}
