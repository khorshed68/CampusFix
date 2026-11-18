//
//  AdminViewModel.swift
//  CampusFix
//
//  Admin-only complaint actions:
//   - update status / priority / remarks / resolution notes
//   - assign a complaint to maintenance staff
//   - demo tool: load sample complaints from sample_issues.json
//
//  Every function first checks `actor.can(...)` (app-side authorization).
//  firestore.rules checks again on the server, so even a modified app
//  cannot perform these actions without a real admin account.
//

import Foundation

@MainActor
final class AdminViewModel: ObservableObject {
    @Published private(set) var isSaving = false
    @Published private(set) var isSeeding = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let firestoreService = FirestoreService()

    /// Shared authorization check. Returns false (and shows a message) if not allowed.
    private func authorize(_ actor: AppUser?, for permission: Permission) -> Bool {
        guard let actor, actor.can(permission) else {
            errorMessage = FirestoreServiceError.permissionDenied.localizedDescription
            return false
        }
        return true
    }

    // MARK: - Manage complaint

    /// Returns true only if Firestore accepted the update.
    func updateIssue(issueId: String?,
                     status: IssueStatus,
                     priority: IssuePriority,
                     adminRemarks: String,
                     resolutionNotes: String,
                     by actor: AppUser?) async -> Bool {
        errorMessage = nil
        guard authorize(actor, for: .manageComplaints),
              authorize(actor, for: .changePriority) else { return false }
        guard let issueId else {
            errorMessage = FirestoreServiceError.missingId.localizedDescription
            return false
        }
        if status == .resolved && resolutionNotes.trimmed.isEmpty {
            errorMessage = "Please add resolution notes before marking a complaint as Resolved."
            return false
        }

        isSaving = true
        defer { isSaving = false }

        do {
            try await firestoreService.updateIssueByAdmin(issueId: issueId,
                                                          status: status,
                                                          priority: priority,
                                                          adminRemarks: adminRemarks.trimmed,
                                                          resolutionNotes: resolutionNotes.trimmed)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Assign to staff

    /// Assigns (staff != nil) or unassigns (staff == nil). Returns true on success.
    func assign(issue: Issue, to staff: AppUser?, by actor: AppUser?) async -> Bool {
        errorMessage = nil
        guard authorize(actor, for: .assignComplaints) else { return false }
        guard let issueId = issue.id else {
            errorMessage = FirestoreServiceError.missingId.localizedDescription
            return false
        }
        if let staff, !(staff.isStaff && staff.isAccountActive) {
            errorMessage = "Complaints can only be assigned to active maintenance staff."
            return false
        }
        if issue.status == .resolved {
            errorMessage = "This complaint is already resolved."
            return false
        }

        isSaving = true
        defer { isSaving = false }

        do {
            try await firestoreService.assignIssue(issueId: issueId, to: staff)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Demo data

    /// Development seed: decodes sample_issues.json and creates one complaint per entry.
    /// Safe: it only ADDS normal "Pending" complaints.
    func seedSampleIssues(admin: AppUser) async {
        errorMessage = nil
        successMessage = nil
        guard authorize(admin, for: .seedSampleData), let adminId = admin.id else { return }

        isSeeding = true
        defer { isSeeding = false }

        do {
            let samples = try JSONService.shared.loadSampleIssues()
            for sample in samples {
                let issue = Issue(title: sample.title,
                                  description: sample.description,
                                  category: sample.category,
                                  building: sample.building,
                                  location: sample.location,
                                  priority: sample.priority,
                                  imageURL: nil,
                                  reportedBy: adminId,
                                  reporterName: "\(admin.name) (sample data)")
                try await firestoreService.createIssue(issue)
            }
            successMessage = "Added \(samples.count) sample complaints."
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
