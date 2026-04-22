import SwiftUI

// MARK: - TaskFormView (Add & Edit)

struct TaskFormView: View {

    @ObservedObject var viewModel: TaskFormViewModel
    @ObservedObject var listViewModel: TaskListViewModel
    @Environment(\.presentationMode) private var presentationMode

    // MARK: Body

    var body: some View {
        NavigationView {
            Form {
                taskInfoSection
                prioritySection
                dueDateSection
                errorSection
            }
            .navigationTitle(viewModel.isEditing ? "Edit Task" : "New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(viewModel.isEditing ? "Update" : "Add") { submitForm() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: Sections

    private var taskInfoSection: some View {
        Section(header: Text("Task Info")) {
            TextField("Title *", text: $viewModel.title)
                .autocapitalization(.sentences)

            ZStack(alignment: .topLeading) {
                if viewModel.description.isEmpty {
                    Text("Description (optional)")
                        .foregroundColor(Color(.placeholderText))
                        .padding(.top, 8)
                        .padding(.leading, 4)
                }
                TextEditor(text: $viewModel.description)
                    .frame(minHeight: 80)
            }
        }
    }

    private var prioritySection: some View {
        Section(header: Text("Priority")) {
            Picker("Priority", selection: $viewModel.priority) {
                ForEach(Priority.allCases, id: \.self) { p in
                    Text(p.rawValue).tag(p)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var dueDateSection: some View {
        Section(header: Text("Due Date")) {
            Toggle("Set Due Date", isOn: $viewModel.hasDueDate.animation())
            if viewModel.hasDueDate {
                DatePicker(
                    "Due Date",
                    selection: $viewModel.dueDate,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
            }
        }
    }

    @ViewBuilder
    private var errorSection: some View {
        if let error = viewModel.validationError {
            Section {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
    }

    // MARK: Actions

    private func submitForm() {
        guard viewModel.validate() else { return }
        let task = viewModel.buildTask()
        if viewModel.isEditing {
            listViewModel.updateTask(task)
        } else {
            listViewModel.addTask(task)
        }
        dismiss()
    }

    private func dismiss() {
        presentationMode.wrappedValue.dismiss()
    }
}
