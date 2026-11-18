//
//  AdminDashboardView.swift
//  CampusFix
//
//  Statistics and recent reports for administrators.
//

import SwiftUI
import Charts

struct AdminDashboardView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @ObservedObject var issueViewModel: IssueViewModel
    @StateObject private var adminViewModel = AdminViewModel()
    @Binding var selectedTab: AdminTab

    @State private var isShowingSeedConfirmation = false

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header

                    if let error = issueViewModel.errorMessage {
                        MessageBanner(message: error) { issueViewModel.errorMessage = nil }
                    }

                    statisticsGrid
                    resolutionCard
                    categoryChart
                    highPriorityQueue
                    recentReports
                    developerTools
                }
                .padding(AppTheme.padding)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Admin Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) { BrandNavigationTitle() }
            }
            .navigationDestination(for: IssueRoute.self) { route in
                IssueDetailView(issueId: route.issueId)
            }
            .confirmationDialog("Add sample complaints?", isPresented: $isShowingSeedConfirmation,
                                titleVisibility: .visible) {
                Button("Add Sample Complaints") {
                    guard let admin = authViewModel.currentUser else { return }
                    Task { await adminViewModel.seedSampleIssues(admin: admin) }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This loads sample_issues.json and creates real Pending complaints in Firestore for demonstration.")
            }
        }
    }

    // MARK: - Sections

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Administrator")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
                Text(authViewModel.currentUser?.name ?? "Admin")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text("\(issueViewModel.statistics.pending) complaints waiting for review")
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

    private var statisticsGrid: some View {
        let stats = issueViewModel.statistics
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Overview", actionTitle: "Manage") {
                selectedTab = .manage
            }
            LazyVGrid(columns: columns, spacing: 12) {
                StatCard(title: "Total Complaints", value: stats.total,
                         iconName: "tray.full.fill", color: AppTheme.navy)
                StatCard(title: "High Priority Open", value: stats.highPriority,
                         iconName: IssuePriority.critical.iconName, color: .red)
                StatCard(title: "Pending", value: stats.pending,
                         iconName: IssueStatus.pending.iconName, color: IssueStatus.pending.color)
                StatCard(title: "In Progress", value: stats.inProgress,
                         iconName: IssueStatus.inProgress.iconName, color: IssueStatus.inProgress.color)
                StatCard(title: "Resolved", value: stats.resolved,
                         iconName: IssueStatus.resolved.iconName, color: IssueStatus.resolved.color)
                StatCard(title: "Unassigned (Open)", value: stats.unassigned,
                         iconName: TaskStage.unassigned.iconName, color: TaskStage.unassigned.color)
                StatCard(title: "Awaiting Staff", value: stats.awaitingAcceptance,
                         iconName: TaskStage.awaitingAcceptance.iconName, color: TaskStage.awaitingAcceptance.color)
                StatCard(title: "Total Upvotes", value: issueViewModel.issues.reduce(0) { $0 + $1.upvoteCount },
                         iconName: "hand.thumbsup.fill", color: AppTheme.skyBlue)
            }
        }
    }

    private var resolutionCard: some View {
        let stats = issueViewModel.statistics
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Resolution Rate")
                    .font(.headline)
                Spacer()
                Text(stats.resolutionRate, format: .percent.precision(.fractionLength(0)))
                    .font(.headline)
                    .foregroundStyle(.green)
            }
            // Stacked bar showing the share of each status
            GeometryReader { proxy in
                HStack(spacing: 2) {
                    ForEach(IssueStatus.allCases) { status in
                        let statusCount = count(for: status)
                        if statusCount > 0 {
                            Rectangle()
                                .fill(status.color)
                                .frame(width: proxy.size.width * CGFloat(statusCount) / CGFloat(max(stats.total, 1)))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.lightBlue)
                .clipShape(Capsule())
            }
            .frame(height: 12)

            HStack(spacing: 14) {
                ForEach(IssueStatus.allCases) { status in
                    Label("\(status.title) \(count(for: status))", systemImage: "circle.fill")
                        .font(.caption2)
                        .foregroundStyle(status.color)
                }
            }
        }
        .cardStyle()
    }

    /// Bar chart of complaints per category (Swift Charts).
    private var categoryChart: some View {
        let grouped = Dictionary(grouping: issueViewModel.issues, by: \.category)
            .map { CategoryCount(category: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }

        return VStack(alignment: .leading, spacing: 12) {
            Text("Complaints by Category")
                .font(.headline)
            if grouped.isEmpty {
                Text("No data yet.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            } else {
                Chart(grouped) { item in
                    BarMark(x: .value("Count", item.count),
                            y: .value("Category", item.category))
                        .foregroundStyle(AppTheme.navy.gradient)
                        .annotation(position: .trailing) {
                            Text("\(item.count)")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                }
                .chartXAxis(.hidden)
                .frame(height: CGFloat(grouped.count) * 34 + 10)
            }
        }
        .cardStyle()
    }

    private var highPriorityQueue: some View {
        let urgent = issueViewModel.issues
            .filter { $0.priority.weight >= IssuePriority.high.weight && $0.status != .resolved }
            .sorted { $0.priority.weight > $1.priority.weight }
            .prefix(3)

        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Needs Attention")
            if urgent.isEmpty {
                Label("No open high-priority complaints.", systemImage: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.green)
                    .cardStyle()
            } else {
                ForEach(Array(urgent)) { issue in
                    issueLink(issue)
                }
            }
        }
    }

    private var recentReports: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Recent Reports", actionTitle: "See all") {
                selectedTab = .manage
            }
            let recent = issueViewModel.recentIssues(limit: 5)
            if recent.isEmpty {
                EmptyStateView(iconName: "tray",
                               title: "No complaints yet",
                               message: "New student reports will appear here in real time.")
                    .cardStyle()
            } else {
                ForEach(recent) { issue in
                    issueLink(issue)
                }
            }
        }
    }

    /// Demo helper so the instructor can see data immediately.
    private var developerTools: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Demo Tools", systemImage: "hammer.fill")
                .font(.headline)
                .foregroundStyle(AppTheme.navy)
            Text("Creates real complaints in Firestore from the bundled sample_issues.json file.")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)

            if let success = adminViewModel.successMessage {
                MessageBanner(message: success, kind: .success) { adminViewModel.successMessage = nil }
            }
            if let error = adminViewModel.errorMessage {
                MessageBanner(message: error) { adminViewModel.errorMessage = nil }
            }

            PrimaryButton(title: "Add Sample Complaints", iconName: "square.and.arrow.down.on.square",
                          style: .outlined, isLoading: adminViewModel.isSeeding) {
                isShowingSeedConfirmation = true
            }
        }
        .cardStyle()
    }

    // MARK: - Helpers

    private func issueLink(_ issue: Issue) -> some View {
        Group {
            if let id = issue.id {
                NavigationLink(value: IssueRoute(issueId: id)) {
                    IssueCardView(issue: issue)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func count(for status: IssueStatus) -> Int {
        issueViewModel.issues.filter { $0.status == status }.count
    }
}

/// One bar in the "Complaints by Category" chart.
private struct CategoryCount: Identifiable {
    let category: String
    let count: Int
    var id: String { category }
}
