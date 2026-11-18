//
//  AssignStaffView.swift
//  CampusFix
//
//  "Complaint Assignment" screen for admins: choose an active maintenance
//  staff member for a complaint, re-assign it, or remove the assignment.
//

import SwiftUI

struct AssignStaffView: View {
    let issue: Issue

    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var userViewModel = UserManagementViewModel()
    @StateObject private var adminViewModel = AdminViewModel()

    @State private var selectedStaffId: String?
    @State private var searchText = ""

    init(issue: Issue) {
        self.issue = issue
        _selectedStaffId = State(initialValue: issue.assignedTo)
    }

    private var filteredStaff: [AppUser] {
        let search = searchText.trimmed.lowercased()
        return userViewModel.activeStaff.filter {
            search.isEmpty || $0.name.lowercased().contains(search) || $0.studentId.lowercased().contains(search)
        }
    }

    private var hasChanges: Bool { selectedStaffId != issue.assignedTo }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(issue.title).font(.headline)
                        Text(issue.fullLocation)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                        HStack(spacing: 6) {
                            BadgeView(item: issue.status, compact: true)
                            BadgeView(item: issue.priority, compact: true)
                        }
                    }
                    .padding(.vertical, 4)
                } footer: {
                    if let current = issue.assignedToName {
                        Text("Currently assigned to \(current)\(issue.isAccepted ? " (accepted)" : " (not yet accepted)"). Re-assigning resets acceptance.")
                    }
                }

                Section("Maintenance Staff") {
                    if userViewModel.isLoading {
                        ProgressView().frame(maxWidth: .infinity)
                    } else if userViewModel.activeStaff.isEmpty {
                        EmptyStateView(iconName: "person.2.slash",
                                       title: "No staff accounts",
                                       message: "Create a maintenance staff account in the Users tab first.")
                    } else {
                        ForEach(filteredStaff) { staff in
                            Button {
                                selectedStaffId = staff.id
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: Role.staff.iconName)
                                        .foregroundStyle(Role.staff.color)
                                        .frame(width: 36, height: 36)
                                        .background(Role.staff.color.opacity(0.12))
                                        .clipShape(Circle())
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(staff.name).foregroundStyle(.primary)
                                        Text("\(staff.studentId) · \(staff.email)")
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.textSecondary)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    if selectedStaffId == staff.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(AppTheme.navy)
                                            .font(.title3)
                                    }
                                }
                            }
                        }
                    }
                }

                if issue.isAssigned {
                    Section {
                        Button(role: .destructive) {
                            selectedStaffId = nil
                        } label: {
                            Label("Remove assignment", systemImage: "person.crop.circle.badge.minus")
                        }
                    }
                }

                if let error = adminViewModel.errorMessage ?? userViewModel.errorMessage {
                    Section {
                        MessageBanner(message: error)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search staff")
            .navigationTitle("Assign Complaint")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if adminViewModel.isSaving {
                        ProgressView()
                    } else {
                        Button(selectedStaffId == nil ? "Unassign" : "Assign") { save() }
                            .fontWeight(.semibold)
                            .disabled(!hasChanges)
                    }
                }
            }
            .onAppear { userViewModel.startListening() }
            .onDisappear { userViewModel.stopListening() }
        }
    }

    private func save() {
        let staff = userViewModel.activeStaff.first { $0.id == selectedStaffId }
        Task {
            let saved = await adminViewModel.assign(issue: issue, to: staff, by: authViewModel.currentUser)
            if saved { dismiss() }
        }
    }
}
