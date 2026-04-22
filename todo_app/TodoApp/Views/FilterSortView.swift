import SwiftUI

// MARK: - FilterSortView

struct FilterSortView: View {

    @ObservedObject var viewModel: TaskListViewModel
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        NavigationView {
            Form {
                // Status Filter
                Section(header: Text("Filter by Status")) {
                    Picker("Status", selection: $viewModel.filter) {
                        ForEach(TaskFilter.allCases, id: \.self) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Priority Filter
                Section(header: Text("Filter by Priority")) {
                    Picker("Priority", selection: $viewModel.priorityFilter) {
                        Text("All").tag(Optional<Priority>.none)
                        ForEach(Priority.allCases, id: \.self) { p in
                            HStack {
                                Circle()
                                    .fill(priorityColor(p))
                                    .frame(width: 8, height: 8)
                                Text(p.rawValue)
                            }
                            .tag(Optional(p))
                        }
                    }
                }

                // Sort Order
                Section(header: Text("Sort By")) {
                    Picker("Sort", selection: $viewModel.sort) {
                        ForEach(TaskSort.allCases, id: \.self) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                }

                // Reset
                Section {
                    Button("Reset Filters & Sort") {
                        viewModel.filter         = .all
                        viewModel.priorityFilter = nil
                        viewModel.sort           = .createdAt
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Filter & Sort")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func priorityColor(_ p: Priority) -> Color {
        switch p {
        case .high:   return .red
        case .medium: return .orange
        case .low:    return .green
        }
    }
}
