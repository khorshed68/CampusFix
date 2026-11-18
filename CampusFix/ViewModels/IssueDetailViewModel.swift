//
//  IssueDetailViewModel.swift
//  CampusFix
//
//  Live data for ONE complaint + the upvote action.
//

import Foundation
import FirebaseFirestore

@MainActor
final class IssueDetailViewModel: ObservableObject {
    @Published private(set) var issue: Issue?
    @Published private(set) var isLoading = true
    @Published private(set) var hasUpvoted = false
    @Published private(set) var isUpvoting = false
    @Published var errorMessage: String?
    @Published private(set) var notFound = false

    private let firestoreService = FirestoreService()
    private var listener: ListenerRegistration?

    /// Called from the view's .onAppear
    func start(issueId: String, userId: String?) {
        guard listener == nil else { return }

        listener = firestoreService.listenToIssue(issueId: issueId) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                self.isLoading = false
                switch result {
                case .success(let issue):
                    self.issue = issue
                    self.notFound = (issue == nil)
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }

        // Check once whether this user already voted.
        if let userId {
            Task {
                do {
                    hasUpvoted = try await firestoreService.hasUpvoted(issueId: issueId, userId: userId)
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    /// Called from the view's .onDisappear – removes the Firestore listener.
    func stop() {
        listener?.remove()
        listener = nil
    }

    func upvote(by user: AppUser?) async {
        guard let user, let userId = user.id, let issueId = issue?.id else { return }
        guard user.can(.upvote) else {
            errorMessage = "Only students can upvote complaints."
            return
        }
        guard !hasUpvoted else {
            errorMessage = FirestoreServiceError.alreadyUpvoted.localizedDescription
            return
        }

        isUpvoting = true
        defer { isUpvoting = false }

        do {
            try await firestoreService.upvote(issueId: issueId, userId: userId)
            hasUpvoted = true   // the listener updates upvoteCount by itself
        } catch {
            // If the server says we already voted, reflect that in the UI.
            if case .alreadyUpvoted? = error as? FirestoreServiceError {
                hasUpvoted = true
            }
            errorMessage = error.localizedDescription
        }
    }
}
