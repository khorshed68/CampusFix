//
//  IssueFilterBar.swift
//  CampusFix
//
//  Horizontal row of filter menus (category, status, priority, sort).
//  It does not own the filter – it edits the parent's @State through @Binding.
//

import SwiftUI

struct IssueFilterBar: View {
    @Binding var filter: IssueFilter
    let categories: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Category
                Menu {
                    Button("All Categories") { filter.category = nil }
                    Divider()
                    ForEach(categories, id: \.self) { category in
                        Button {
                            filter.category = category
                        } label: {
                            Label(category, systemImage: CategoryIcon.name(for: category))
                        }
                    }
                } label: {
                    FilterChip(title: filter.category ?? "Category",
                               iconName: "square.grid.2x2",
                               isActive: filter.category != nil)
                }

                // Status
                Menu {
                    Button("All Statuses") { filter.status = nil }
                    Divider()
                    ForEach(IssueStatus.allCases) { status in
                        Button {
                            filter.status = status
                        } label: {
                            Label(status.title, systemImage: status.iconName)
                        }
                    }
                } label: {
                    FilterChip(title: filter.status?.title ?? "Status",
                               iconName: "circle.dashed",
                               isActive: filter.status != nil)
                }

                // Priority
                Menu {
                    Button("All Priorities") { filter.priority = nil }
                    Divider()
                    ForEach(IssuePriority.allCases) { priority in
                        Button {
                            filter.priority = priority
                        } label: {
                            Label(priority.title, systemImage: priority.iconName)
                        }
                    }
                } label: {
                    FilterChip(title: filter.priority?.title ?? "Priority",
                               iconName: "flag",
                               isActive: filter.priority != nil)
                }

                // Sort
                Menu {
                    Picker("Sort by", selection: $filter.sort) {
                        ForEach(IssueSortOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                } label: {
                    FilterChip(title: filter.sort.rawValue,
                               iconName: "arrow.up.arrow.down",
                               isActive: filter.sort != .latest)
                }

                if filter.isActive {
                    Button {
                        filter.category = nil
                        filter.status = nil
                        filter.priority = nil
                    } label: {
                        Label("Clear", systemImage: "xmark.circle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.red)
                    }
                }
            }
            .padding(.horizontal, AppTheme.padding)
            .padding(.vertical, 4)
        }
    }
}

private struct FilterChip: View {
    let title: String
    let iconName: String
    let isActive: Bool

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: iconName)
            Text(title)
                .lineLimit(1)
            Image(systemName: "chevron.down")
                .font(.system(size: 9, weight: .bold))
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .foregroundStyle(isActive ? .white : AppTheme.navy)
        .background(isActive ? AppTheme.navy : AppTheme.card)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(AppTheme.lightBlue, lineWidth: isActive ? 0 : 1))
    }
}
