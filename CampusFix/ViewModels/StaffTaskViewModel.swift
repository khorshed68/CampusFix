//
//  StaffTaskViewModel.swift
//  CampusFix
//
//  Actions for maintenance staff on complaints ASSIGNED TO THEM:
//   1. Accept the task
//   2. Update progress: In Progress -> Resolved, with work description and resolution notes
//
//  Staff cannot assign tasks, change priority, or manage users.
//  firestore.rules enforces "only the assigned staff member" on the server.
//

import Foundation

@MainActor
final class StaffTaskViewModel: ObservableObject {
    @Published private(set) var isSaving = false
    @Published var errorMessage: String?

    private let firestoreService = FirestoreService()

    /// The staff member must have the permission AND be the one assigned.
    private func authorize(_ staff: AppUser?, for issue: Issue) -> Bool {
        guard let staff, staff.can(.updateAssignedTask), issue.isAssignedTo(staff.id) else {
            errorMessage = "Only the maintenance staff member assigned to this complaint can update it."
            return false
        }
        return true
    }

    func acceptTask(_ issue: Issue, by staff: AppUser?) async -> Bool {
        errorMessage = nil
        guard authorize(staff, for: issue), let issueId = issue.id else { return false }
        guard !issue.isAccepted else { return true }

        isSaving = true
        defer { isSaving = false }

        do {
            try await firestoreService.acceptTask(issueId: issueId)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    /// Staff may only choose In Progress or Resolved.
    static let allowedStatuses: [IssueStatus] = [.inProgress, .resolved]

    func updateProgress(_ issue: Issue,
                        status: IssueStatus,
                        workDescription: String,
                        resolutionNotes: String,
                        by staff: AppUser?) async -> Bool {
        errorMessage = nil
        guard authorize(staff, for: issue), let issueId = issue.id else { return false }
        guard issue.isAccepted else {
            errorMessage = "Please accept the task before updating its progress."
            return false
        }
        guard Self.allowedStatuses.contains(status) else {
            errorMessage = "Staff can set the status to In Progress or Resolved only."
            return false
        }
        if workDescription.trimmed.isEmpty {
            errorMessage = "Please describe the work you have done."
            return false
        }
        if status == .resolved && resolutionNotes.trimmed.isEmpty {
            errorMessage = "Please add resolution notes before marking the task as Resolved."
            return false
        }

        isSaving = true
        defer { isSaving = false }

        do {
            try await firestoreService.updateTaskProgress(issueId: issueId,
                                                          status: status,
                                                          workDescription: workDescription.trimmed,
                                                          resolutionNotes: resolutionNotes.trimmed)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
