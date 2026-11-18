//
//  IssueStatistics.swift
//  CampusFix
//
//  Dashboard numbers calculated from a list of issues.
//  Shared by the student dashboard and the admin dashboard,
//  so the counting logic is written only once.
//

import Foundation

struct IssueStatistics {
    let total: Int
    let pending: Int
    let inProgress: Int
    let resolved: Int
    let highPriority: Int   // High + Critical that are not yet resolved
    let unassigned: Int     // open complaints with no staff member yet
    let awaitingAcceptance: Int

    init(issues: [Issue]) {
        unassigned = issues.filter { $0.taskStage == .unassigned }.count
        awaitingAcceptance = issues.filter { $0.taskStage == .awaitingAcceptance }.count
        total = issues.count
        pending = issues.filter { $0.status == .pending }.count
        inProgress = issues.filter { $0.status == .inProgress }.count
        resolved = issues.filter { $0.status == .resolved }.count
        highPriority = issues.filter {
            $0.priority.weight >= IssuePriority.high.weight && $0.status != .resolved
        }.count
    }

    /// Percentage of complaints that are resolved (0...1), for the progress bar.
    var resolutionRate: Double {
        total == 0 ? 0 : Double(resolved) / Double(total)
    }
}
