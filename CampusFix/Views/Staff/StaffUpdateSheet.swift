//
//  StaffUpdateSheet.swift
//  CampusFix
//
//  Maintenance staff updates the progress of THEIR accepted task:
//  status (In Progress / Resolved), work description and resolution notes.
//

import SwiftUI

struct StaffUpdateSheet: View {
    let issue: Issue

    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = StaffTaskViewModel()

    @State private var status: IssueStatus
    @State private var workDescription: String
    @State private var resolutionNotes: String

    init(issue: Issue) {
        self.issue = issue
        // A Pending task starts the form at "In Progress".
        _status = State(initialValue: issue.status == .pending ? .inProgress : issue.status)
        _workDescription = State(initialValue: issue.workDescription ?? "")
        _resolutionNotes = State(initialValue: issue.resolutionNotes)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(issue.title).font(.headline)
                        Text(issue.fullLocation)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                        BadgeView(item: issue.priority, compact: true)
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Picker("Status", selection: $status) {
                        ForEach(StaffTaskViewModel.allowedStatuses) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Task Progress")
                } footer: {
                    Text("Staff can move a task to In Progress or Resolved. Only an admin can set it back to Pending.")
                }

                Section {
                    TextField("e.g. Checked wiring, replacing capacitor", text: $workDescription, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Work Description")
                } footer: {
                    Text("Visible to the student and the admin.")
                }

                Section {
                    TextField("e.g. Fan motor replaced and tested", text: $resolutionNotes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Resolution Notes")
                } footer: {
                    Text("Required when marking the task as Resolved.")
                }

                if let error = viewModel.errorMessage {
                    Section {
                        MessageBanner(message: error) { viewModel.errorMessage = nil }
                    }
                }
            }
            .navigationTitle("Update Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isSaving {
                        ProgressView()
                    } else {
                        Button("Save") { save() }
                            .fontWeight(.semibold)
                    }
                }
            }
            .interactiveDismissDisabled(viewModel.isSaving)
        }
    }

    private func save() {
        Task {
            let saved = await viewModel.updateProgress(issue,
                                                       status: status,
                                                       workDescription: workDescription,
                                                       resolutionNotes: resolutionNotes,
                                                       by: authViewModel.currentUser)
            if saved { dismiss() }
        }
    }
}
