//
//  AuthViewModel.swift
//  CampusFix
//
//  Owns the login session for the whole app.
//  Created once in CampusFixApp with @StateObject and shared with every
//  screen through .environmentObject(...) -> read with @EnvironmentObject.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor   // all @Published changes happen on the main (UI) thread
final class AuthViewModel: ObservableObject {

    /// Which part of the app should be visible right now.
    enum SessionState {
        case loading                         // checking saved session
        case signedOut                       // show Login
        case profileUnavailable(String?)     // logged in, but no Firestore profile (yet)
        case signedIn(AppUser)               // show Student or Admin app
    }

    @Published private(set) var sessionState: SessionState = .loading
    @Published private(set) var currentUser: AppUser?
    @Published var errorMessage: String?
    @Published private(set) var isWorking = false

    private let authService = AuthService()
    private let firestoreService = FirestoreService()

    // Listener handles – kept so we can remove the listeners explicitly.
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private var profileListener: ListenerRegistration?

    // MARK: - Session monitoring

    /// Starts watching Firebase Auth. Safe to call more than once.
    func startSessionMonitoring() {
        guard FirebaseService.isConfigured, authStateHandle == nil else { return }

        authStateHandle = authService.addAuthStateListener { [weak self] userId in
            // Firebase calls us from a callback, so hop onto the main actor.
            Task { @MainActor in
                self?.handleAuthChange(userId: userId)
            }
        }
    }

    private func handleAuthChange(userId: String?) {
        // Always remove the old profile listener before starting a new one.
        profileListener?.remove()
        profileListener = nil

        guard let userId else {
            currentUser = nil
            sessionState = .signedOut
            return
        }

        sessionState = .loading
        profileListener = firestoreService.listenToUserProfile(userId: userId) { [weak self] result in
            Task { @MainActor in
                self?.handleProfileResult(result)
            }
        }
    }

    private func handleProfileResult(_ result: Result<AppUser?, Error>) {
        switch result {
        case .success(let user?) where !user.isAccountActive:
            // An admin deactivated this account. The live listener applies it instantly.
            currentUser = nil
            sessionState = .profileUnavailable("Your account has been deactivated by an administrator. Please contact the campus maintenance office.")
        case .success(let user?):
            currentUser = user
            sessionState = .signedIn(user)
        case .success(nil):
            // Happens for a split second right after registering, before the
            // profile document is written. The listener fires again once it exists.
            currentUser = nil
            sessionState = .profileUnavailable(nil)
        case .failure(let error):
            currentUser = nil
            sessionState = .profileUnavailable(error.localizedDescription)
        }
    }

    // MARK: - Login

    func login(email: String, password: String) async {
        errorMessage = nil
        let email = email.trimmed

        guard email.isValidEmail else {
            errorMessage = "Please enter a valid email address."
            return
        }
        guard !password.isEmpty else {
            errorMessage = "Please enter your password."
            return
        }

        isWorking = true
        defer { isWorking = false }

        do {
            try await authService.login(email: email, password: password)
            // No navigation code needed: the auth listener above switches screens.
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Registration

    /// Returns an error message, or nil if all fields are valid.
    func validateRegistration(name: String, email: String, studentId: String,
                              password: String, confirmPassword: String) -> String? {
        if name.trimmed.count < 3 { return "Please enter your full name (at least 3 characters)." }
        if !email.trimmed.isValidEmail { return "Please enter a valid email address." }
        if studentId.trimmed.isEmpty { return "Please enter your student ID." }
        if studentId.trimmed.count < 4 { return "Student ID looks too short." }
        if password.count < AppConstants.minPasswordLength {
            return "Password must be at least \(AppConstants.minPasswordLength) characters."
        }
        if password != confirmPassword { return "Passwords do not match." }
        return nil
    }

    func register(name: String, email: String, studentId: String,
                  password: String, confirmPassword: String) async {
        errorMessage = nil
        if let problem = validateRegistration(name: name, email: email, studentId: studentId,
                                              password: password, confirmPassword: confirmPassword) {
            errorMessage = problem
            return
        }

        isWorking = true
        defer { isWorking = false }

        do {
            // Step 1: create the Firebase Auth account
            let userId = try await authService.register(email: email.trimmed, password: password)

            // Step 2: save the profile in Firestore.
            // The role is ALWAYS "student" here. Security rules also reject
            // any attempt to self-register as "admin".
            let profile = AppUser(name: name.trimmed,
                                  email: email.trimmed.lowercased(),
                                  studentId: studentId.trimmed,
                                  role: .student,
                                  isActive: true)
            do {
                try await firestoreService.createUserProfile(profile, userId: userId)
            } catch {
                // Undo step 1 so the student can try registering again.
                await authService.deleteCurrentAccount()
                throw error
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Profile

    /// Returns true on success so the edit screen can close itself.
    func updateProfile(name: String, studentId: String) async -> Bool {
        errorMessage = nil
        guard let userId = currentUser?.id else { return false }
        guard name.trimmed.count >= 3 else {
            errorMessage = "Please enter your full name (at least 3 characters)."
            return false
        }
        if currentUser?.isStudent == true && studentId.trimmed.isEmpty {
            errorMessage = "Please enter your student ID."
            return false
        }

        isWorking = true
        defer { isWorking = false }

        do {
            try await firestoreService.updateUserProfile(userId: userId,
                                                         name: name.trimmed,
                                                         studentId: studentId.trimmed)
            return true   // the profile listener updates currentUser automatically
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Logout

    func logout() {
        do {
            try authService.logout()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
