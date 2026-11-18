//
//  UserManagementViewModel.swift
//  CampusFix
//
//  Admin-only account management:
//   - live list of all users
//   - create maintenance staff accounts (trusted, admin-only provisioning)
//   - change a user's role between Student and Maintenance Staff
//   - activate / deactivate accounts
//
//  Admin accounts themselves are NOT managed here: they are set in the
//  Firebase Console by the project owner, and the rules forbid changing them.
//

import Foundation
import FirebaseFirestore

@MainActor
final class UserManagementViewModel: ObservableObject {
    @Published private(set) var users: [AppUser] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isWorking = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let firestoreService = FirestoreService()
    private let authService = AuthService()
    private var listener: ListenerRegistration?

    // MARK: - Listener

    func startListening() {
        guard listener == nil else { return }
        isLoading = users.isEmpty
        listener = firestoreService.listenToUsers { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                self.isLoading = false
                switch result {
                case .success(let users): self.users = users
                case .failure(let error): self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    // MARK: - Queries

    func users(withRole role: Role?, matching search: String) -> [AppUser] {
        let search = search.trimmed.lowercased()
        return users.filter { user in
            (role == nil || user.role == role)
                && (search.isEmpty
                    || user.name.lowercased().contains(search)
                    || user.email.lowercased().contains(search)
                    || user.studentId.lowercased().contains(search))
        }
    }

    /// Staff who can receive new assignments.
    var activeStaff: [AppUser] {
        users.filter { $0.isStaff && $0.isAccountActive }
    }

    func count(of role: Role) -> Int {
        users.filter { $0.role == role }.count
    }

    // MARK: - Authorization helper

    private func authorize(_ actor: AppUser?) -> Bool {
        guard let actor, actor.can(.manageUsers) else {
            errorMessage = FirestoreServiceError.permissionDenied.localizedDescription
            return false
        }
        return true
    }

    /// Admins can't edit other admins or themselves from the app.
    func canEdit(_ user: AppUser, actor: AppUser?) -> Bool {
        guard let actor, actor.can(.manageUsers) else { return false }
        return !user.isAdmin && user.id != actor.id
    }

    // MARK: - Create staff account

    func validateStaffForm(name: String, email: String, staffId: String, password: String) -> String? {
        if name.trimmed.count < 3 { return "Please enter the staff member's full name." }
        if !email.trimmed.isValidEmail { return "Please enter a valid email address." }
        if staffId.trimmed.isEmpty { return "Please enter a staff ID." }
        if password.count < AppConstants.minPasswordLength {
            return "Temporary password must be at least \(AppConstants.minPasswordLength) characters."
        }
        return nil
    }

    /// Creates the Firebase Auth account (without logging the admin out) and
    /// the Firestore profile with role = staff. Returns true on success.
    func createStaffAccount(name: String, email: String, staffId: String,
                            password: String, by actor: AppUser?) async -> Bool {
        errorMessage = nil
        successMessage = nil
        guard authorize(actor) else { return false }
        if let problem = validateStaffForm(name: name, email: email, staffId: staffId, password: password) {
            errorMessage = problem
            return false
        }

        isWorking = true
        defer { isWorking = false }

        let profile = AppUser(name: name.trimmed,
                              email: email.trimmed.lowercased(),
                              studentId: staffId.trimmed,
                              role: .staff,
                              isActive: true)
        let service = firestoreService
        do {
            try await authService.createAccountForAnotherUser(email: email.trimmed,
                                                              password: password) { newUserId in
                // Written with the ADMIN's session -> rules check isAdmin().
                try await service.createUserProfile(profile, userId: newUserId)
            }
            successMessage = "Staff account created for \(profile.name). Share the temporary password with them privately."
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Change role / active state

    func updateAccess(for user: AppUser, role: Role, isActive: Bool, by actor: AppUser?) async -> Bool {
        errorMessage = nil
        successMessage = nil
        guard authorize(actor) else { return false }
        guard canEdit(user, actor: actor), let userId = user.id else {
            errorMessage = "Administrator accounts can only be changed in the Firebase Console."
            return false
        }
        guard role != .admin else {
            errorMessage = "Admin privileges can only be granted in the Firebase Console."
            return false
        }

        isWorking = true
        defer { isWorking = false }

        do {
            try await firestoreService.updateUserAccess(userId: userId, role: role, isActive: isActive)
            successMessage = "\(user.name) updated."
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
