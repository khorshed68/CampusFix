//
//  StudentDashboardView.swift
//  CampusFix
//

import SwiftUI

struct StudentDashboardView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel

    /// LAB TOPIC @ObservedObject: the ViewModel was created by the parent
    /// (StudentTabView); this view only observes it.
    @ObservedObject var issueViewModel: IssueViewModel

    /// LAB TOPIC @Binding: lets this child change the parent's selected tab.
    @Binding var selectedTab: StudentTab

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    welcomeHeader

                    if let error = issueViewModel.errorMessage {
                        MessageBanner(message: error) { issueViewModel.errorMessage = nil }
                    }

                    statistics
                    quickReportCard
                    myActivity
                    recentComplaints
                }
                .padding(AppTheme.padding)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) { BrandNavigationTitle() }
            }
            .navigationDestination(for: IssueRoute.self) { route in
                IssueDetailView(issueId: route.issueId)
            }
        }
    }

    // MARK: - Sections

    private var welcomeHeader: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Welcome back,")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                Text(authViewModel.currentUser?.firstName ?? "Student")
                    .font(.title.bold())
                    .foregroundStyle(.white)
                Text("Together we keep our campus in great shape.")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.85))
            }
            Spacer(minLength: 0)
            CampusFixLogo(size: 72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(AppTheme.headerGradient)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
    }

    private var statistics: some View {
        let stats = issueViewModel.statistics
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Campus Overview")
            if issueViewModel.isLoading {
                ProgressView().frame(maxWidth: .infinity).padding()
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    StatCard(title: "Total Reported", value: stats.total,
                             iconName: "tray.full.fill", color: AppTheme.navy)
                    StatCard(title: "Pending", value: stats.pending,
                             iconName: IssueStatus.pending.iconName, color: IssueStatus.pending.color)
                    StatCard(title: "In Progress", value: stats.inProgress,
                             iconName: IssueStatus.inProgress.iconName, color: IssueStatus.inProgress.color)
                    StatCard(title: "Resolved", value: stats.resolved,
                             iconName: IssueStatus.resolved.iconName, color: IssueStatus.resolved.color)
                }
            }
        }
    }

    private var quickReportCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "exclamationmark.bubble.fill")
                .font(.title2)
                .foregroundStyle(AppTheme.navy)
                .frame(width: 50, height: 50)
                .background(AppTheme.lightBlue)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text("Spotted a problem?")
                    .font(.headline)
                Text("Report it in under a minute.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
            Button {
                selectedTab = .report       // writes through the @Binding
            } label: {
                Text("Report")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(AppTheme.navy)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
        .cardStyle()
    }

    private var myActivity: some View {
        let myIssues = issueViewModel.issues(reportedBy: authViewModel.currentUser?.id)
        let myStats = IssueStatistics(issues: myIssues)
        return Button {
            selectedTab = .myReports
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("My Reports")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("\(myStats.total) submitted · \(myStats.resolved) resolved")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                ProgressView(value: myStats.resolutionRate)
                    .frame(width: 70)
                    .tint(.green)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .cardStyle()
        }
        .buttonStyle(.plain)
    }

    private var recentComplaints: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Recent Complaints", actionTitle: "See all") {
                selectedTab = .issues
            }

            let recent = issueViewModel.recentIssues(limit: 5)
            if recent.isEmpty && !issueViewModel.isLoading {
                EmptyStateView(iconName: "checkmark.circle",
                               title: "No complaints yet",
                               message: "Be the first to report a campus problem.",
                               buttonTitle: "Report an Issue") {
                    selectedTab = .report
                }
                .cardStyle()
            } else {
                // LAB TOPIC ForEach: builds one card per complaint
                ForEach(recent) { issue in
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
