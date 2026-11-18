//
//  Issue.swift
//  CampusFix
//
//  A campus maintenance complaint, stored in Firestore at  issues/{issueId}.
//  Upvotes are stored separately in  issues/{issueId}/votes/{userId}.
//

import SwiftUI
import FirebaseFirestore

struct Issue: Codable, Identifiable {
    @DocumentID var id: String? = nil

    // Filled in by the student
    var title: String
    var description: String
    var category: String        // one of the categories from campus_data.json
    var building: String        // one of the buildings from campus_data.json
    var location: String        // free text, e.g. "Room 304, 3rd floor"
    var priority: IssuePriority
    var imageURL: String?       // public ImgBB image URL (optional)

    // Filled in automatically
    var reportedBy: String      // Auth UID of the student
    var reporterName: String
    @ServerTimestamp var reportedAt: Date? = nil   // set by the Firestore server, not the phone clock
    var upvoteCount: Int

    // Managed only by admins (protected by security rules)
    var status: IssueStatus
    var adminRemarks: String
    var resolutionNotes: String
    var updatedAt: Date? = nil

    // Assignment (set by admin) – optional so complaints created before
    // assignment existed still decode correctly.
    var assignedTo: String? = nil        // Auth UID of the maintenance staff member
    var assignedToName: String? = nil
    var assignedAt: Date? = nil

    // Task progress (set by the assigned staff member)
    var acceptedAt: Date? = nil          // when staff accepted the task
    var workDescription: String? = nil   // what the staff member did / is doing

    /// Convenience initializer for a brand-new complaint.
    /// Status always starts as Pending and counters start at zero.
    init(title: String,
         description: String,
         category: String,
         building: String,
         location: String,
         priority: IssuePriority,
         imageURL: String?,
         reportedBy: String,
         reporterName: String) {
        self.title = title
        self.description = description
        self.category = category
        self.building = building
        self.location = location
        self.priority = priority
        self.imageURL = imageURL
        self.reportedBy = reportedBy
        self.reporterName = reporterName
        self.upvoteCount = 0
        self.status = .pending
        self.adminRemarks = ""
        self.resolutionNotes = ""
    }

    /// "Academic Building · Room 304"
    var fullLocation: String {
        location.isEmpty ? building : "\(building) · \(location)"
    }

    var isAssigned: Bool { assignedTo != nil }
    var isAccepted: Bool { acceptedAt != nil }

    func isAssignedTo(_ userId: String?) -> Bool {
        guard let userId else { return false }
        return assignedTo == userId
    }

    /// Where the complaint is in the maintenance workflow.
    var taskStage: TaskStage {
        if status == .resolved { return .completed }
        if !isAssigned { return .unassigned }
        if !isAccepted { return .awaitingAcceptance }
        return .active
    }
}

/// The maintenance workflow, used by the staff screens and assignment labels.
enum TaskStage: String, CaseIterable, Identifiable, BadgeDisplayable {
    case unassigned = "Unassigned"
    case awaitingAcceptance = "New Task"
    case active = "Accepted"
    case completed = "Completed"

    var id: String { rawValue }
    var title: String { rawValue }

    var color: Color {
        switch self {
        case .unassigned: return .gray
        case .awaitingAcceptance: return .purple
        case .active: return .blue
        case .completed: return .green
        }
    }

    var iconName: String {
        switch self {
        case .unassigned: return "person.crop.circle.badge.questionmark"
        case .awaitingAcceptance: return "bell.badge.fill"
        case .active: return "hammer.fill"
        case .completed: return "checkmark.circle.fill"
        }
    }
}

/// A small Hashable value used for NavigationStack navigation.
/// We navigate by ID (not the whole Issue) because the details screen
/// listens to the live document itself.
struct IssueRoute: Hashable {
    let issueId: String
}
