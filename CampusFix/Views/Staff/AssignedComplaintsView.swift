//
//  AssignedComplaintsView.swift
//  CampusFix
//
//  The "Assigned Complaints" screen: every complaint assigned to the
//  logged-in staff member, filtered by workflow stage.
//

import SwiftUI

struct AssignedComplaintsView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @ObservedObject var issueViewModel: IssueViewModel

    /// nil = show all stages
    @State private var stageFilter: TaskStage? = nil
    @State private var searchText = ""

    /// Stages a staff member can see (they never see "Unassigned").
    private let stages: [TaskStage] = [.awaitingAcceptance, .active, .completed]

    var body: some View {
        NavigationStack {
            let myTasks = issueViewModel.issues(assignedTo: authViewModel.currentUser?.id)
            let search = searchText.trimmed.lowercased()
            let visible = myTasks.filter { issue in
                (stageFilter == nil || issue.taskStage == stageFilter)
                    && (search.isEmpty
                        || issue.title.lowercased().contains(search)
                        || issue.fullLocation.lowercased().contains(search))
            }

            List {
                Section {
                    Picker("Stage", selection: $stageFilter) {
                        Text("All").tag(TaskStage?.none)
                        ForEach(stages) { stage in
                            Text(stage.title).tag(TaskStage?.some(stage))
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
                    } else if myTasks.isEmpty {
                        EmptyStateView(iconName: "tray",
                                       title: "No tasks assigned",
                                       message: "When an administrator assigns a complaint to you, it will appear here.")
                            .listRowBackground(Color.clear)
                    } else if visible.isEmpty {
                        EmptyStateView(iconName: "line.3.horizontal.decrease.circle",
                                       title: "Nothing here",
                                       message: "No tasks match this filter.")
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(visible) { issue in
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
            .searchable(text: $searchText, prompt: "Search my tasks")
            .navigationTitle("Assigned Complaints")
            .navigationDestination(for: IssueRoute.self) { route in
                IssueDetailView(issueId: route.issueId)
            }
        }
    }
}
