//
//  IssueStatus.swift
//  CampusFix
//
//  Enums for complaint status and priority.
//  Both are stored in Firestore as plain strings (their rawValue),
//  e.g. "Pending", "In Progress", "Resolved".
//

import SwiftUI

// MARK: - Protocol (Lab concept: Protocols)

/// Anything that can be shown as a small coloured "pill" badge.
/// IssueStatus and IssuePriority both adopt this protocol, so one reusable
/// `BadgeView` (see Views/Components/BadgeView.swift) can display either of them.
protocol BadgeDisplayable {
    var title: String { get }
    var color: Color { get }
    var iconName: String { get }
}

// MARK: - Issue Status

/// The life-cycle of a complaint. Only an admin may change it (enforced by firestore.rules).
enum IssueStatus: String, Codable, CaseIterable, Identifiable, BadgeDisplayable {
    case pending = "Pending"
    case inProgress = "In Progress"
    case resolved = "Resolved"

    var id: String { rawValue }
    var title: String { rawValue }

    /// Required colours: Pending = orange, In Progress = blue, Resolved = green.
    var color: Color {
        switch self {
        case .pending: return .orange
        case .inProgress: return .blue
        case .resolved: return .green
        }
    }

    var iconName: String {
        switch self {
        case .pending: return "clock.fill"
        case .inProgress: return "wrench.and.screwdriver.fill"
        case .resolved: return "checkmark.seal.fill"
        }
    }
}

// MARK: - Issue Priority

enum IssuePriority: String, Codable, CaseIterable, Identifiable, BadgeDisplayable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"

    var id: String { rawValue }
    var title: String { rawValue }

    var color: Color {
        switch self {
        case .low: return .gray
        case .medium: return .teal
        case .high: return .orange
        case .critical: return .red
        }
    }

    var iconName: String {
        switch self {
        case .low: return "arrow.down.circle.fill"
        case .medium: return "equal.circle.fill"
        case .high: return "arrow.up.circle.fill"
        case .critical: return "exclamationmark.triangle.fill"
        }
    }

    /// Used for sorting: a higher number means more urgent.
    var weight: Int {
        switch self {
        case .low: return 0
        case .medium: return 1
        case .high: return 2
        case .critical: return 3
        }
    }
}
