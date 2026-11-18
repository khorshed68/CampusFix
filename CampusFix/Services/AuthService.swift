//
//  AuthService.swift
//  CampusFix
//
//  Thin wrapper around Firebase Authentication.
//  Views never talk to Firebase directly; they go through a ViewModel,
//  which uses this service (MVVM).
//

import Foundation
import FirebaseCore
import FirebaseAuth

/// Friendly error messages for common Firebase Auth errors.
enum AuthServiceError: LocalizedError {
    case message(String)

    var errorDescription: String? {
        switch self {
        case .message(let text): return text
        }
    }

    /// Converts a raw Firebase error into a message a student understands.
    static func friendly(_ error: Error) -> AuthServiceError {
        let nsError = error as NSError
        // "FIRAuthErrorDomain" is the error domain used by Firebase Authentication.
        guard nsError.domain == "FIRAuthErrorDomain",
              let code = AuthErrorCode(rawValue: nsError.code) else {
            return .message(error.localizedDescription)
        }
        switch code {
        case .invalidEmail:
            return .message("Please enter a valid email address.")
        case .emailAlreadyInUse:
            return .message("An account with this email already exists. Try logging in.")
        case .weakPassword:
            return .message("Password is too weak. Use at least \(AppConstants.minPasswordLength) characters.")
        case .wrongPassword, .invalidCredential, .userNotFound:
            return .message("Incorrect email or password.")
        case .userDisabled:
            return .message("This account has been disabled. Contact the administrator.")
        case .networkError:
            return .message("No internet connection. Please check your network and try again.")
        case .tooManyRequests:
            return .message("Too many attempts. Please wait a moment and try again.")
        default:
            return .message(error.localizedDescription)
        }
    }
}

final class AuthService {
    /// Computed (not stored) so Firebase is only touched after it is configured.
    private var auth: Auth { Auth.auth() }

    /// UID of the logged-in user, or nil if nobody is logged in.
    var currentUserId: String? { auth.currentUser?.uid }

    /// Firebase calls the closure every time the user logs in or out.
    /// Firebase also restores the previous session automatically on app launch
    /// (session persistence), and this listener reports it.
    /// The returned handle must be kept so we can remove the listener later.
    func addAuthStateListener(_ onChange: @escaping (String?) -> Void) -> AuthStateDidChangeListenerHandle {
        auth.addStateDidChangeListener { _, user in
            onChange(user?.uid)
        }
    }

    func removeAuthStateListener(_ handle: AuthStateDidChangeListenerHandle) {
        auth.removeStateDidChangeListener(handle)
    }

    /// Creates a Firebase Auth account and returns the new user's UID.
    func register(email: String, password: String) async throws -> String {
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            return result.user.uid
        } catch {
            throw AuthServiceError.friendly(error)
        }
    }

    func login(email: String, password: String) async throws {
        do {
            _ = try await auth.signIn(withEmail: email, password: password)
        } catch {
            throw AuthServiceError.friendly(error)
        }
    }

    func logout() throws {
        do {
            try auth.signOut()
        } catch {
            throw AuthServiceError.friendly(error)
        }
    }

    /// Used only to undo a half-finished registration (Auth account created
    /// but the Firestore profile could not be saved).
    func deleteCurrentAccount() async {
        try? await auth.currentUser?.delete()
    }

    // MARK: - Admin: create an account for someone else

    /// Creates a Firebase Auth account for a NEW staff member WITHOUT logging
    /// the admin out.
    ///
    /// Why a second FirebaseApp? `createUser` always signs in as the new user.
    /// Running it on a separate, temporary Firebase instance keeps the admin's
    /// own session untouched.
    ///
    /// `saveProfile` is called with the new UID; the admin's (main) session writes
    /// the Firestore profile, so firestore.rules can check that the caller is an admin.
    /// If saving the profile fails, the new Auth account is deleted again.
    func createAccountForAnotherUser(email: String,
                                     password: String,
                                     saveProfile: (String) async throws -> Void) async throws {
        let secondaryAuth = try makeSecondaryAuth()
        defer { try? secondaryAuth.signOut() }

        let newUserId: String
        do {
            newUserId = try await secondaryAuth.createUser(withEmail: email, password: password).user.uid
        } catch {
            throw AuthServiceError.friendly(error)
        }

        do {
            try await saveProfile(newUserId)
        } catch {
            try? await secondaryAuth.currentUser?.delete()   // undo
            throw error
        }
    }

    private func makeSecondaryAuth() throws -> Auth {
        let appName = "CampusFixAccountCreator"
        if let existing = FirebaseApp.app(name: appName) {
            return Auth.auth(app: existing)
        }
        guard let options = FirebaseApp.app()?.options else {
            throw AuthServiceError.message("Firebase is not configured.")
        }
        FirebaseApp.configure(name: appName, options: options)
        guard let secondaryApp = FirebaseApp.app(name: appName) else {
            throw AuthServiceError.message("Could not prepare account creation.")
        }
        return Auth.auth(app: secondaryApp)
    }
}
