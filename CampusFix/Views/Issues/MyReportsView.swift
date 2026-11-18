//
//  MyReportsView.swift
//  CampusFix
//
//  Complaints submitted by the logged-in student, with their latest status
//  and admin remarks.
//

import SwiftUI

struct MyReportsView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @ObservedObject var issueViewModel: IssueViewModel
    @Binding var selectedTab: StudentTab

    @State private var statusFilter: IssueStatus? = nil   // nil = All

    var body: some View {
        NavigationStack {
            let myIssues = issueViewModel.issues(reportedBy: authViewModel.currentUser?.id)
            let visibleIssues = myIssues.filter { statusFilter == nil || $0.status == statusFilter }

            List {
                Section {
                    Picker("Status", selection: $statusFilter) {
                        Text("All").tag(IssueStatus?.none)
                        ForEach(IssueStatus.allCases) { status in
                            Text(status.title).tag(IssueStatus?.some(status))
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                Section {
                    if issueViewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .listRowBackground(Color.clear)
                    } else if myIssues.isEmpty {
                        EmptyStateView(iconName: "doc.text.magnifyingglass",
                                       title: "No reports yet",
                                       message: "Complaints you submit will appear here so you can track their progress.",
                                       buttonTitle: "Report an Issue") {
                            selectedTab = .report
                        }
                        .listRowBackground(Color.clear)
                    } else if visibleIssues.isEmpty {
                        EmptyStateView(iconName: "line.3.horizontal.decrease.circle",
                                       title: "Nothing here",
                                       message: "You have no complaints with this status.")
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(visibleIssues) { issue in
                            IssueRow(issue: issue, showLatestUpdate: true)
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
            .navigationTitle("My Reports")
            .navigationDestination(for: IssueRoute.self) { route in
                IssueDetailView(issueId: route.issueId)
            }
        }
    }
}
