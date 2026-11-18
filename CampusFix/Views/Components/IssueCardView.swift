//
//  IssueCardView.swift
//  CampusFix
//
//  The rounded card used in every complaint list.
//

import SwiftUI

struct IssueCardView: View {
    let issue: Issue
    var showLatestUpdate = false   // My Reports shows the admin's latest remark

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                // Category icon
                Image(systemName: CategoryIcon.name(for: issue.category))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.navy)
                    .frame(width: 42, height: 42)
                    .background(AppTheme.lightBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(issue.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Label(issue.fullLocation, systemImage: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                if issue.imageURL != nil {
                    Image(systemName: "photo")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            HStack(spacing: 6) {
                BadgeView(item: issue.status, compact: true)
                BadgeView(item: issue.priority, compact: true)
                Text(issue.category)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }

            if let staffName = issue.assignedToName, issue.status != .resolved {
                Label("Assigned to \(staffName)\(issue.isAccepted ? "" : " · awaiting acceptance")",
                      systemImage: "person.crop.circle.badge.checkmark")
                    .font(.caption)
                    .foregroundStyle(.purple)
                    .lineLimit(1)
            }

            if showLatestUpdate, let work = issue.workDescription, !work.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "hammer.fill")
                        .font(.caption2)
                        .foregroundStyle(.purple)
                    Text("Staff: \(work)")
                        .font(.caption)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                }
            }

            if showLatestUpdate, !issue.adminRemarks.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "bubble.left.fill")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.skyBlue)
                    Text("Admin: \(issue.adminRemarks)")
                        .font(.caption)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.lightBlue.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            Divider()

            HStack {
                Label(issue.reportedAt.relativeOrJustNow, systemImage: "clock")
                Spacer()
                Label("\(issue.upvoteCount)", systemImage: "hand.thumbsup.fill")
                    .foregroundStyle(AppTheme.navy)
            }
            .font(.caption)
            .foregroundStyle(AppTheme.textSecondary)
        }
        .cardStyle()
        .accessibilityElement(children: .combine)
    }
}
