//
//  IssueDetailView.swift
//  CampusFix
//
//  Full details of one complaint, updated live from Firestore.
//  What you can DO here depends on your role:
//    Student -> upvote
//    Staff   -> accept task / update progress (only if assigned to you)
//    Admin   -> assign to staff / manage status, priority, notes
//

import SwiftUI

struct IssueDetailView: View {
    let issueId: String

    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var viewModel = IssueDetailViewModel()
    @StateObject private var staffViewModel = StaffTaskViewModel()

    /// Which sheet is open (only one at a time).
    enum ActiveSheet: String, Identifiable {
        case manage, assign, staffUpdate
        var id: String { rawValue }
    }
    @State private var activeSheet: ActiveSheet?

    private var currentUser: AppUser? { authViewModel.currentUser }

    /// Permission checks decide which controls appear (the server checks again).
    private func can(_ permission: Permission) -> Bool {
        currentUser?.can(permission) ?? false
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(message: "Loading complaint…")
            } else if let issue = viewModel.issue {
                content(for: issue)
            } else {
                EmptyStateView(iconName: "questionmark.folder",
                               title: "Complaint not found",
                               message: viewModel.errorMessage ?? "It may have been removed.")
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Issue Details")
        .navigationBarTitleDisplayMode(.inline)
        // LAB TOPIC onAppear: start the live listener for this complaint
        .onAppear {
            viewModel.start(issueId: issueId, userId: authViewModel.currentUser?.id)
        }
        // LAB TOPIC onDisappear: remove the listener when leaving the screen.
        // start() is safe to call again if the screen re-appears.
        .onDisappear {
            viewModel.stop()
        }
        .sheet(item: $activeSheet) { sheet in
            if let issue = viewModel.issue {
                switch sheet {
                case .manage: AdminUpdateSheet(issue: issue)
                case .assign: AssignStaffView(issue: issue)
                case .staffUpdate: StaffUpdateSheet(issue: issue)
                }
            }
        }
    }

    // MARK: - Content

    private func content(for issue: Issue) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                IssueImageView(urlString: issue.imageURL)

                // Title + badges
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        BadgeView(item: issue.status)
                        BadgeView(item: issue.priority)
                    }
                    Text(issue.title)
                        .font(.title2.bold())
                        .foregroundStyle(AppTheme.navy)
                    TagView(text: issue.category, iconName: CategoryIcon.name(for: issue.category))
                    Text(issue.description)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()

                if let error = viewModel.errorMessage {
                    MessageBanner(message: error) { viewModel.errorMessage = nil }
                }

                if let error = staffViewModel.errorMessage {
                    MessageBanner(message: error) { staffViewModel.errorMessage = nil }
                }

                roleActions(for: issue)
                upvoteCard(for: issue)
                infoCard(for: issue)
                StatusProgressView(status: issue.status)
                updatesCard(for: issue)
            }
            .padding(AppTheme.padding)
        }
    }

    private func upvoteCard(for issue: Issue) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(issue.upvoteCount)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.navy)
                    .contentTransition(.numericText())
                Text(issue.upvoteCount == 1 ? "student affected" : "students affected")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
            if can(.upvote) {
                Button {
                    Task { await viewModel.upvote(by: currentUser) }
                } label: {
                    HStack(spacing: 6) {
                        if viewModel.isUpvoting {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: viewModel.hasUpvoted ? "hand.thumbsup.fill" : "hand.thumbsup")
                        }
                        Text(viewModel.hasUpvoted ? "Upvoted" : "Upvote")
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 11)
                    .foregroundStyle(viewModel.hasUpvoted ? AppTheme.navy : .white)
                    .background(viewModel.hasUpvoted ? AppTheme.lightBlue : AppTheme.navy)
                    .clipShape(Capsule())
                }
                .disabled(viewModel.hasUpvoted || viewModel.isUpvoting)
                .accessibilityHint("Shows that this problem affects you too. You can upvote only once.")
            }
        }
        .cardStyle()
    }

    private func infoCard(for issue: Issue) -> some View {
        VStack(spacing: 12) {
            InfoRow(iconName: "building.2.fill", label: "Building", value: issue.building)
            Divider()
            InfoRow(iconName: "mappin.and.ellipse", label: "Location", value: issue.location)
            Divider()
            InfoRow(iconName: "calendar", label: "Reported",
                    value: issue.reportedAt?.fullDescription ?? "Just now")
            Divider()
            InfoRow(iconName: "person.fill", label: "Reported by", value: issue.reporterName)
            Divider()
            HStack {
                Label("Assignment", systemImage: "person.crop.circle.badge.checkmark")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer(minLength: 16)
                VStack(alignment: .trailing, spacing: 4) {
                    Text(issue.assignedToName ?? "Not assigned yet")
                        .font(.subheadline.weight(.medium))
                    BadgeView(item: issue.taskStage, compact: true)
                }
            }
            if let updatedAt = issue.updatedAt {
                Divider()
                InfoRow(iconName: "clock.arrow.circlepath", label: "Last update",
                        value: updatedAt.relativeDescription)
            }
        }
        .cardStyle()
    }

    /// Buttons that depend on the user's role.
    @ViewBuilder
    private func roleActions(for issue: Issue) -> some View {
        if can(.assignComplaints) || can(.manageComplaints) {
            // ADMIN
            VStack(spacing: 10) {
                if can(.assignComplaints) && issue.status != .resolved {
                    PrimaryButton(title: issue.isAssigned ? "Reassign Staff" : "Assign to Staff",
                                  iconName: "person.crop.circle.badge.plus") {
                        activeSheet = .assign
                    }
                }
                if can(.manageComplaints) {
                    PrimaryButton(title: "Manage Complaint", iconName: "slider.horizontal.3",
                                  style: .outlined) {
                        activeSheet = .manage
                    }
                }
            }
        } else if can(.updateAssignedTask) {
            // MAINTENANCE STAFF
            if issue.isAssignedTo(currentUser?.id) {
                switch issue.taskStage {
                case .awaitingAcceptance:
                    VStack(alignment: .leading, spacing: 10) {
                        Label("This complaint has been assigned to you.", systemImage: "bell.badge.fill")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.purple)
                        PrimaryButton(title: "Accept Task", iconName: "hand.raised.fill",
                                      isLoading: staffViewModel.isSaving) {
                            Task { _ = await staffViewModel.acceptTask(issue, by: currentUser) }
                        }
                    }
                    .cardStyle()
                case .active:
                    PrimaryButton(title: "Update Progress", iconName: "hammer.fill") {
                        activeSheet = .staffUpdate
                    }
                case .completed:
                    Label("You completed this task.", systemImage: "checkmark.seal.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.green)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .cardStyle()
                case .unassigned:
                    EmptyView()
                }
            } else {
                Label("This complaint is not assigned to you (read-only).", systemImage: "lock.fill")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()
            }
        }
    }

    private func updatesCard(for issue: Issue) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Updates from Administration", systemImage: "megaphone.fill")
                .font(.headline)
                .foregroundStyle(AppTheme.navy)

            NoteBlock(title: "Admin Remarks",
                      text: issue.adminRemarks,
                      placeholder: "No remarks yet.",
                      color: AppTheme.skyBlue)
            NoteBlock(title: "Maintenance Work",
                      text: issue.workDescription ?? "",
                      placeholder: issue.isAssigned ? "Work has not started yet." : "Not assigned to staff yet.",
                      color: .purple)
            NoteBlock(title: "Resolution Notes",
                      text: issue.resolutionNotes,
                      placeholder: issue.status == .resolved ? "Resolved without notes." : "Not resolved yet.",
                      color: .green)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

// MARK: - Small subviews

private struct InfoRow: View {
    let iconName: String
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Label(label, systemImage: iconName)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
            Spacer(minLength: 16)
            Text(value.isEmpty ? "—" : value)
                .font(.subheadline.weight(.medium))
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct NoteBlock: View {
    let title: String
    let text: String
    let placeholder: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 4)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(color)
                Text(text.isEmpty ? placeholder : text)
                    .font(.subheadline)
                    .foregroundStyle(text.isEmpty ? AppTheme.textSecondary : .primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// Three-step progress tracker: Pending -> In Progress -> Resolved.
struct StatusProgressView: View {
    let status: IssueStatus

    private var currentIndex: Int {
        IssueStatus.allCases.firstIndex(of: status) ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                .font(.headline)
                .foregroundStyle(AppTheme.navy)

            HStack(spacing: 0) {
                ForEach(Array(IssueStatus.allCases.enumerated()), id: \.element) { index, step in
                    let reached = index <= currentIndex
                    VStack(spacing: 6) {
                        Image(systemName: reached ? step.iconName : "circle")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(reached ? .white : AppTheme.textSecondary)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(reached ? step.color : AppTheme.background))
                        Text(step.title)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(reached ? step.color : AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)

                    if index < IssueStatus.allCases.count - 1 {
                        Rectangle()
                            .fill(index < currentIndex ? IssueStatus.allCases[index + 1].color : AppTheme.lightBlue)
                            .frame(height: 3)
                            .frame(maxWidth: 40)
                            .offset(y: -10)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}
