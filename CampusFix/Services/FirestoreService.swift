//
//  FirestoreService.swift
//  CampusFix
//
//  All Cloud Firestore reads and writes live here.
//
//  Firestore structure:
//    users/{userId}                    -> AppUser
//    issues/{issueId}                  -> Issue
//    issues/{issueId}/votes/{userId}   -> one document per upvote
//
//  IMPORTANT: The app's checks are only for a nice user experience.
//  The REAL protection is firestore.rules on the server.
//

import Foundation
import FirebaseFirestore

enum FirestoreServiceError: LocalizedError {
    case alreadyUpvoted
    case missingId
    case permissionDenied
    case other(String)

    var errorDescription: String? {
        switch self {
        case .alreadyUpvoted: return "You have already upvoted this complaint."
        case .missingId: return "This complaint could not be identified."
        case .permissionDenied: return "You do not have permission to do this."
        case .other(let message): return message
        }
    }

    /// Turns Firestore's error codes into friendly messages.
    static func friendly(_ error: Error) -> Error {
        if error is FirestoreServiceError { return error }
        let nsError = error as NSError
        if nsError.domain == FirestoreErrorDomain,
           let code = FirestoreErrorCode.Code(rawValue: nsError.code) {
            switch code {
            case .permissionDenied:
                return FirestoreServiceError.permissionDenied
            case .unavailable:
                return FirestoreServiceError.other("The server is unreachable. Check your internet connection.")
            default:
                break
            }
        }
        return FirestoreServiceError.other(error.localizedDescription)
    }
}

final class FirestoreService {
    /// Computed so Firestore is only accessed after FirebaseApp.configure().
    private var db: Firestore { Firestore.firestore() }

    private var usersCollection: CollectionReference {
        db.collection(AppConstants.Collections.users)
    }

    private var issuesCollection: CollectionReference {
        db.collection(AppConstants.Collections.issues)
    }

    // MARK: - Users

    /// Saves a new user profile. The document ID is the Auth UID,
    /// which is how security rules know who owns the profile.
    func createUserProfile(_ user: AppUser, userId: String) async throws {
        do {
            // Firestore.Encoder converts our Codable struct into a dictionary.
            let data = try Firestore.Encoder().encode(user)
            try await usersCollection.document(userId).setData(data)
        } catch {
            throw FirestoreServiceError.friendly(error)
        }
    }

    /// Students may change only their name and student ID (role is protected by rules).
    func updateUserProfile(userId: String, name: String, studentId: String) async throws {
        do {
            try await usersCollection.document(userId).updateData([
                "name": name,
                "studentId": studentId
            ])
        } catch {
            throw FirestoreServiceError.friendly(error)
        }
    }

    /// Real-time listener on one user profile (so a role change in the console
    /// is picked up without restarting the app).
    /// `onChange` receives the profile, nil if it doesn't exist yet, or an error.
    func listenToUserProfile(userId: String,
                             onChange: @escaping (Result<AppUser?, Error>) -> Void) -> ListenerRegistration {
        usersCollection.document(userId).addSnapshotListener { snapshot, error in
            if let error {
                onChange(.failure(FirestoreServiceError.friendly(error)))
                return
            }
            guard let snapshot, snapshot.exists else {
                onChange(.success(nil))
                return
            }
            do {
                onChange(.success(try snapshot.data(as: AppUser.self)))
            } catch {
                onChange(.failure(FirestoreServiceError.other("Your profile data is invalid: \(error.localizedDescription)")))
            }
        }
    }

    // MARK: - Issues (read)

    /// Real-time listener for ALL complaints, newest first.
    /// Firestore calls the closure immediately with current data, and again
    /// every time any complaint is added or changed.
    func listenToIssues(onChange: @escaping (Result<[Issue], Error>) -> Void) -> ListenerRegistration {
        issuesCollection
            .order(by: "reportedAt", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error {
                    onChange(.failure(FirestoreServiceError.friendly(error)))
                    return
                }
                // compactMap skips any document that fails to decode instead of crashing.
                let issues = snapshot?.documents.compactMap { try? $0.data(as: Issue.self) } ?? []
                onChange(.success(issues))
            }
    }

    /// Real-time listener for ONE complaint (used by the details screen).
    func listenToIssue(issueId: String,
                       onChange: @escaping (Result<Issue?, Error>) -> Void) -> ListenerRegistration {
        issuesCollection.document(issueId).addSnapshotListener { snapshot, error in
            if let error {
                onChange(.failure(FirestoreServiceError.friendly(error)))
                return
            }
            guard let snapshot, snapshot.exists else {
                onChange(.success(nil))
                return
            }
            do {
                onChange(.success(try snapshot.data(as: Issue.self)))
            } catch {
                onChange(.failure(FirestoreServiceError.other("This complaint's data is invalid.")))
            }
        }
    }

    // MARK: - Issues (write)

    /// Creates a complaint. Firestore generates the document ID.
    /// reportedAt is filled with the SERVER time because of @ServerTimestamp.
    @discardableResult
    func createIssue(_ issue: Issue) async throws -> String {
        do {
            let data = try Firestore.Encoder().encode(issue)
            let reference = issuesCollection.document()   // new auto-ID
            try await reference.setData(data)
            return reference.documentID
        } catch {
            throw FirestoreServiceError.friendly(error)
        }
    }

    /// Admin only: update status, priority, remarks and resolution notes.
    /// Security rules reject this call for students and staff.
    func updateIssueByAdmin(issueId: String,
                            status: IssueStatus,
                            priority: IssuePriority,
                            adminRemarks: String,
                            resolutionNotes: String) async throws {
        do {
            try await issuesCollection.document(issueId).updateData([
                "status": status.rawValue,
                "priority": priority.rawValue,
                "adminRemarks": adminRemarks,
                "resolutionNotes": resolutionNotes,
                "updatedAt": FieldValue.serverTimestamp()
            ])
        } catch {
            throw FirestoreServiceError.friendly(error)
        }
    }

    // MARK: - Assignment (admin)

    /// Assigns a complaint to a staff member, or removes the assignment (staff == nil).
    /// Re-assigning clears `acceptedAt`, so the new staff member must accept it again.
    /// Rules check that the caller is an admin and the target is an active staff member.
    func assignIssue(issueId: String, to staff: AppUser?) async throws {
        var changes: [String: Any] = [
            "acceptedAt": FieldValue.delete(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        if let staff, let staffId = staff.id {
            changes["assignedTo"] = staffId
            changes["assignedToName"] = staff.name
            changes["assignedAt"] = FieldValue.serverTimestamp()
        } else {
            changes["assignedTo"] = FieldValue.delete()
            changes["assignedToName"] = FieldValue.delete()
            changes["assignedAt"] = FieldValue.delete()
        }
        do {
            try await issuesCollection.document(issueId).updateData(changes)
        } catch {
            throw FirestoreServiceError.friendly(error)
        }
    }

    // MARK: - Staff tasks

    /// Staff accepts an assigned task. Rules allow this only for the assigned staff member.
    func acceptTask(issueId: String) async throws {
        do {
            try await issuesCollection.document(issueId).updateData([
                "acceptedAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp()
            ])
        } catch {
            throw FirestoreServiceError.friendly(error)
        }
    }

    /// Staff updates progress on their own accepted task.
    /// Rules: status may only become In Progress or Resolved, and Resolved needs notes.
    func updateTaskProgress(issueId: String,
                            status: IssueStatus,
                            workDescription: String,
                            resolutionNotes: String) async throws {
        do {
            try await issuesCollection.document(issueId).updateData([
                "status": status.rawValue,
                "workDescription": workDescription,
                "resolutionNotes": resolutionNotes,
                "updatedAt": FieldValue.serverTimestamp()
            ])
        } catch {
            throw FirestoreServiceError.friendly(error)
        }
    }

    // MARK: - User management (admin)

    /// Live list of every user profile. Rules allow this query only for admins.
    func listenToUsers(onChange: @escaping (Result<[AppUser], Error>) -> Void) -> ListenerRegistration {
        usersCollection
            .order(by: "name")
            .addSnapshotListener { snapshot, error in
                if let error {
                    onChange(.failure(FirestoreServiceError.friendly(error)))
                    return
                }
                let users = snapshot?.documents.compactMap { try? $0.data(as: AppUser.self) } ?? []
                onChange(.success(users))
            }
    }

    /// Admin changes a user's role (student <-> staff only; admin roles are
    /// managed in the Firebase Console) and/or active flag.
    func updateUserAccess(userId: String, role: Role, isActive: Bool) async throws {
        do {
            try await usersCollection.document(userId).updateData([
                "role": role.rawValue,
                "isActive": isActive
            ])
        } catch {
            throw FirestoreServiceError.friendly(error)
        }
    }

    // MARK: - Upvotes

    /// Has this user already voted? (checks issues/{id}/votes/{userId})
    func hasUpvoted(issueId: String, userId: String) async throws -> Bool {
        do {
            let vote = try await voteReference(issueId: issueId, userId: userId).getDocument()
            return vote.exists
        } catch {
            throw FirestoreServiceError.friendly(error)
        }
    }

    /// Adds one upvote using a TRANSACTION, so two things happen together or not at all:
    ///   1. create the vote document  issues/{id}/votes/{userId}
    ///   2. increase upvoteCount by exactly 1
    /// Because the vote document ID is the user's UID, a user can never have two votes.
    /// The security rules also check both steps on the server.
    func upvote(issueId: String, userId: String) async throws {
        let issueRef = issuesCollection.document(issueId)
        let voteRef = voteReference(issueId: issueId, userId: userId)

        do {
            _ = try await db.runTransaction { (transaction, errorPointer) -> Any? in
                do {
                    let existingVote = try transaction.getDocument(voteRef)
                    if existingVote.exists {
                        errorPointer?.pointee = FirestoreServiceError.alreadyUpvoted as NSError
                        return nil
                    }
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }

                transaction.setData([
                    "userId": userId,
                    "votedAt": FieldValue.serverTimestamp()
                ], forDocument: voteRef)
                transaction.updateData([
                    "upvoteCount": FieldValue.increment(Int64(1))
                ], forDocument: issueRef)
                return nil
            }
        } catch {
            throw FirestoreServiceError.friendly(error)
        }
    }

    private func voteReference(issueId: String, userId: String) -> DocumentReference {
        issuesCollection.document(issueId)
            .collection(AppConstants.Collections.votes)
            .document(userId)
    }
}
