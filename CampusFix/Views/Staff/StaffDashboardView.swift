//
//  StaffDashboardView.swift
//  CampusFix
//
//  Maintenance Staff home: task counts and the next tasks to work on.
//

import SwiftUI

struct StaffDashboardView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @ObservedObject var issueViewModel: IssueViewModel
    @Binding var selectedTab: StaffTab

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    /// Only complaints assigned to the logged-in staff member.
    private var myTasks: [Issue] {
        issueViewModel.issues(assignedTo: authViewModel.currentUser?.id)
    }

    private func count(_ stage: TaskStage) -> Int {
        myTasks.filter { $0.taskStage == stage }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header

                    if let error = issueViewModel.errorMessage {
                        MessageBanner(message: error) { issueViewModel.errorMessage = nil }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "My Workload", actionTitle: "All tasks") {
                            selectedTab = .assigned
                        }
                        LazyVGrid(columns: columns, spacing: 12) {
                            StatCard(title: "Assigned to Me", value: myTasks.count,
                                     iconName: "tray.full.fill", color: AppTheme.navy)
                            StatCard(title: "New (Not Accepted)", value: count(.awaitingAcceptance),
                                     iconName: TaskStage.awaitingAcceptance.iconName,
                                     color: TaskStage.awaitingAcceptance.color)
                            StatCard(title: "Accepted / Working", value: count(.active),
                                     iconName: TaskStage.active.iconName, color: TaskStage.active.color)
                            StatCard(title: "Completed", value: count(.completed),
                                     iconName: TaskStage.completed.iconName, color: TaskStage.completed.color)
                        }
                    }

                    nextTasks
                }
                .padding(AppTheme.padding)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Staff Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) { BrandNavigationTitle() }
            }
            .navigationDestination(for: IssueRoute.self) { route in
                IssueDetailView(issueId: route.issueId)
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Maintenance Staff")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
                Text(authViewModel.currentUser?.name ?? "Staff")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text("\(count(.awaitingAcceptance)) new task(s) waiting for you")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.85))
            }
            Spacer(minLength: 0)
            CampusFixLogo(size: 72)
        }
        .padding(20)
        .background(AppTheme.headerGradient)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
    }

    /// Open tasks, most urgent first.
    private var nextTasks: some View {
        let open = myTasks
            .filter { $0.status != .resolved }
            .sorted { $0.priority.weight > $1.priority.weight }

        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Up Next")
            if issueViewModel.isLoading {
                ProgressView().frame(maxWidth: .infinity).padding()
            } else if open.isEmpty {
                EmptyStateView(iconName: "checkmark.seal",
                               title: "All caught up",
                               message: "You have no open tasks. New assignments from the admin will appear here instantly.")
                    .cardStyle()
            } else {
                ForEach(open.prefix(5)) { issue in
                    if let id = issue.id {
                        NavigationLink(value: IssueRoute(issueId: id)) {
                            IssueCardView(issue: issue)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
