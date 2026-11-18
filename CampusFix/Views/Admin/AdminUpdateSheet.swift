//
//  AdminUpdateSheet.swift
//  CampusFix
//
//  Admin form to change status, priority, remarks and resolution notes.
//  Saving calls Firestore; firestore.rules rejects it unless the user is an admin.
//

import SwiftUI

struct AdminUpdateSheet: View {
    let issue: Issue

    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss          // LAB TOPIC @Environment
    @StateObject private var adminViewModel = AdminViewModel()

    @State private var status: IssueStatus
    @State private var priority: IssuePriority
    @State private var adminRemarks: String
    @State private var resolutionNotes: String

    init(issue: Issue) {
        self.issue = issue
        // Start the form with the complaint's current values.
        _status = State(initialValue: issue.status)
        _priority = State(initialValue: issue.priority)
        _adminRemarks = State(initialValue: issue.adminRemarks)
        _resolutionNotes = State(initialValue: issue.resolutionNotes)
    }

    private var hasChanges: Bool {
        status != issue.status
            || priority != issue.priority
            || adminRemarks.trimmed != issue.adminRemarks
            || resolutionNotes.trimmed != issue.resolutionNotes
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(issue.title)
                            .font(.headline)
                        Text(issue.fullLocation)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                        HStack {
                            BadgeView(item: issue.taskStage, compact: true)
                            Text(issue.assignedToName.map { "Assigned to \($0)" } ?? "Not assigned")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Status") {
                    Picker("Status", selection: $status) {
                        ForEach(IssueStatus.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    BadgeView(item: status)
                }

                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        ForEach(IssuePriority.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    TextField("e.g. Electrician assigned, visit scheduled for Monday",
                              text: $adminRemarks, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Administrative Remarks")
                } footer: {
                    Text("Visible to all students on the complaint's details screen.")
                }

                Section {
                    TextField("e.g. Fan motor replaced and tested", text: $resolutionNotes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Resolution Notes")
                } footer: {
                    Text("Required when marking a complaint as Resolved.")
                }

                if let error = adminViewModel.errorMessage {
                    Section {
                        MessageBanner(message: error) { adminViewModel.errorMessage = nil }
                    }
                }
            }
            .navigationTitle("Manage Complaint")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if adminViewModel.isSaving {
                        ProgressView()
                    } else {
                        Button("Save") { save() }
                            .fontWeight(.semibold)
                            .disabled(!hasChanges)
                    }
                }
            }
            .interactiveDismissDisabled(adminViewModel.isSaving)
        }
    }

    private func save() {
        Task {
            let saved = await adminViewModel.updateIssue(issueId: issue.id,
                                                         status: status,
                                                         priority: priority,
                                                         adminRemarks: adminRemarks,
                                                         resolutionNotes: resolutionNotes,
                                                         by: authViewModel.currentUser)
            if saved { dismiss() }   // close only after Firestore confirmed the update
        }
    }
}
