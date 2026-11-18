//
//  BadgeView.swift
//  CampusFix
//
//  A generic pill badge. Works with ANY type that adopts the
//  BadgeDisplayable protocol (IssueStatus, IssuePriority).
//

import SwiftUI

struct BadgeView<Item: BadgeDisplayable>: View {
    let item: Item
    var compact = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: item.iconName)
                .font(.system(size: compact ? 9 : 11, weight: .bold))
            Text(item.title)
                .font(.system(size: compact ? 11 : 12, weight: .semibold))
        }
        .padding(.horizontal, compact ? 8 : 10)
        .padding(.vertical, compact ? 4 : 5)
        .foregroundStyle(item.color)
        .background(item.color.opacity(0.14))
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
    }
}

/// A small grey tag for plain text such as the category name.
struct TagView: View {
    let text: String
    let iconName: String

    var body: some View {
        Label(text, systemImage: iconName)
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .foregroundStyle(AppTheme.navy)
            .background(AppTheme.lightBlue)
            .clipShape(Capsule())
    }
}
