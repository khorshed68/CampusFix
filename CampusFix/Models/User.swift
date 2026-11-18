//
//  User.swift
//  CampusFix
//
//  The user profile stored in Firestore at  users/{userId}.
//  Named `AppUser` (not `User`) so it never clashes with FirebaseAuth.User.
//

import SwiftUI
import FirebaseFirestore

// MARK: - Role (Role-Based Access Control)

/// The three roles of CampusFix. Stored in Firestore as "student", "staff", "admin".
///
/// How each role is created:
///  - student : self-registration in the app (the ONLY role you can give yourself)
///  - staff   : created by an admin in User Management (or promoted from student)
///  - admin   : set manually by the project owner in the Firebase Console
///
/// The server (firestore.rules) enforces all of this, not just the app.
enum Role: String, Codable, CaseIterable, Identifiable, BadgeDisplayable {
    case student
    case staff
    case admin

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .student: return "Student"
        case .staff: return "Maintenance Staff"
        case .admin: return "Administrator"
        }
    }

    // BadgeDisplayable – so the generic BadgeView can show a role badge.
    var title: String { displayName }

    var color: Color {
        switch self {
        case .student: return AppTheme.skyBlue
        case .staff: return .purple
        case .admin: return AppTheme.navy
        }
    }

    var iconName: String {
        switch self {
        case .student: return "graduationcap.fill"
        case .staff: return "wrench.and.screwdriver.fill"
        case .admin: return "person.badge.shield.checkmark.fill"
        }
    }

    /// Label for the `studentId` field (staff and admins use it as a staff ID).
    var idFieldLabel: String {
        self == .student ? "Student ID" : "Staff ID"
    }

    /// The permission table. One place that answers "can this role do X?".
    func can(_ permission: Permission) -> Bool {
        permissions.contains(permission)
    }

    private var permissions: Set<Permission> {
        switch self {
        case .student:
            return [.reportIssue, .upvote, .viewOwnReports]
        case .staff:
            return [.viewAssignedTasks, .updateAssignedTask]
        case .admin:
            return [.manageComplaints, .assignComplaints, .changePriority,
                    .manageUsers, .viewStatistics, .seedSampleData]
        }
    }
}

/// Every protected action in the app.
/// ViewModels check these before calling Firebase, and views use them to decide
/// which buttons to show. firestore.rules repeats the same checks on the server.
enum Permission {
    case reportIssue          // submit a complaint
    case upvote               // upvote a complaint
    case viewOwnReports       // "My Reports"
    case viewAssignedTasks    // staff task list
    case updateAssignedTask   // accept task, set In Progress / Resolved, add work notes
    case manageComplaints     // change status, remarks, resolution notes
    case assignComplaints     // assign a complaint to maintenance staff
    case changePriority       // change a complaint's priority
    case manageUsers          // create staff accounts, change roles, deactivate users
    case viewStatistics       // admin dashboard statistics
    case seedSampleData       // demo tool
}

// MARK: - AppUser

/// A struct (value type) that conforms to Codable, so Firestore can convert
/// it to / from a document automatically.
struct AppUser: Codable, Identifiable {
    /// @DocumentID tells Firestore to fill this with the document's ID (the Auth UID).
    /// It is NOT written as a field inside the document.
    @DocumentID var id: String? = nil

    var name: String
    var email: String
    var studentId: String          // student ID for students, staff ID for staff/admin
    var role: Role
    /// Admins can deactivate accounts. Optional so older profiles without
    /// this field still decode (missing = active).
    var isActive: Bool? = nil
    @ServerTimestamp var createdAt: Date? = nil

    var isAdmin: Bool { role == .admin }
    var isStaff: Bool { role == .staff }
    var isStudent: Bool { role == .student }
    var isAccountActive: Bool { isActive ?? true }

    /// Shortcut: `user.can(.assignComplaints)`. A deactivated user can do nothing.
    func can(_ permission: Permission) -> Bool {
        isAccountActive && role.can(permission)
    }

    /// First name for friendly greetings, e.g. "Welcome back, Rahim".
    var firstName: String {
        name.split(separator: " ").first.map(String.init) ?? name
    }
}
