//
//  AllIssuesView.swift
//  CampusFix
//
//  Searchable, filterable list of every complaint.
//  Used by students ("All Issues") AND by admins ("Manage Complaints"),
//  so the list code exists only once.
//

import SwiftUI

struct AllIssuesView: View {
    @ObservedObject var issueViewModel: IssueViewModel
    let title: String

    /// LAB TOPIC @State: search text + selected filters are local UI state.
    @State private var filter = IssueFilter()

    var body: some View {
        NavigationStack {
            let results = issueViewModel.filteredIssues(using: filter)

            // LAB TOPIC List + ForEach
            List {
                Section {
                    IssueFilterBar(filter: $filter, categories: issueViewModel.categories)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)

                    if let error = issueViewModel.errorMessage {
                        MessageBanner(message: error) { issueViewModel.errorMessage = nil }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }

                    Text("\(results.count) of \(issueViewModel.issues.count) complaints")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

                Section {
                    if issueViewModel.isLoading {
                        ProgressView("Loading complaints…")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .listRowBackground(Color.clear)
                    } else if results.isEmpty {
                        EmptyStateView(iconName: "magnifyingglass",
                                       title: "No complaints found",
                                       message: issueViewModel.issues.isEmpty
                                           ? "No complaints have been reported yet."
                                           : "Try a different search or clear the filters.")
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(results) { issue in
                            IssueRow(issue: issue)
                                .listRowInsets(EdgeInsets(top: 6, leading: AppTheme.padding,
                                                          bottom: 6, trailing: AppTheme.padding))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(AppTheme.background.ignoresSafeArea())
            .searchable(text: $filter.searchText, prompt: "Search title, building, location")
            .navigationTitle(title)
            .navigationDestination(for: IssueRoute.self) { route in
                IssueDetailView(issueId: route.issueId)
            }
        }
    }
}

/// A card that opens the details screen. The invisible NavigationLink
/// avoids the default list chevron so the card design stays clean.
struct IssueRow: View {
    let issue: Issue
    var showLatestUpdate = false

    var body: some View {
        ZStack {
            if let id = issue.id {
                NavigationLink(value: IssueRoute(issueId: id)) { EmptyView() }
                    .opacity(0)
            }
            IssueCardView(issue: issue, showLatestUpdate: showLatestUpdate)
        }
    }
}
