//
//  IssueViewModel.swift
//  CampusFix
//
//  Keeps the live list of ALL complaints from Firestore and provides
//  searching, filtering, sorting and statistics.
//
//  One instance is created with @StateObject in StudentTabView / AdminTabView,
//  and passed to child screens, which receive it with @ObservedObject.
//

import Foundation
import FirebaseFirestore

/// How the All Issues list is ordered.
enum IssueSortOption: String, CaseIterable, Identifiable {
    case latest = "Latest"
    case mostUpvoted = "Most Upvoted"
    case priority = "Highest Priority"

    var id: String { rawValue }
}

/// The current search + filter choices.
/// The VIEW owns this with @State (it is local UI state), and the filter bar
/// changes it through a @Binding.
struct IssueFilter {
    var searchText = ""
    var category: String? = nil        // nil means "All categories"
    var status: IssueStatus? = nil     // nil means "All statuses"
    var priority: IssuePriority? = nil // nil means "All priorities"
    var sort: IssueSortOption = .latest

    var isActive: Bool {
        category != nil || status != nil || priority != nil
    }
}

@MainActor
final class IssueViewModel: ObservableObject {
    @Published private(set) var issues: [Issue] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    /// Categories for the filter menu, decoded from campus_data.json.
    @Published private(set) var categories: [String] = []

    private let firestoreService = FirestoreService()
    private var listener: ListenerRegistration?

    // MARK: - Listener lifecycle

    /// Starts the real-time Firestore listener (does nothing if already running).
    func startListening() {
        guard listener == nil else { return }
        isLoading = issues.isEmpty
        listener = firestoreService.listenToIssues { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                self.isLoading = false
                switch result {
                case .success(let issues):
                    self.issues = issues
                    self.errorMessage = nil
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    /// Removes the listener. Called explicitly (e.g. when the tab view
    /// disappears on logout) so we never keep listening after sign-out.
    func stopListening() {
        listener?.remove()
        listener = nil
    }

    // MARK: - JSON campus data

    func loadCategories() {
        guard categories.isEmpty else { return }
        do {
            categories = try JSONService.shared.loadCampusData().categories
        } catch {
            categories = CampusData.fallback.categories
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Search, filter, sort

    func filteredIssues(using filter: IssueFilter) -> [Issue] {
        let search = filter.searchText.trimmed.lowercased()

        // 1. Filter (closures passed to `filter`)
        let matching = issues.filter { issue in
            let matchesSearch = search.isEmpty
                || issue.title.lowercased().contains(search)
                || issue.description.lowercased().contains(search)
                || issue.building.lowercased().contains(search)
                || issue.location.lowercased().contains(search)
            let matchesCategory = filter.category == nil || issue.category == filter.category
            let matchesStatus = filter.status == nil || issue.status == filter.status
            let matchesPriority = filter.priority == nil || issue.priority == filter.priority
            return matchesSearch && matchesCategory && matchesStatus && matchesPriority
        }

        // 2. Sort (Firestore already returns newest first)
        switch filter.sort {
        case .latest:
            return matching
        case .mostUpvoted:
            return matching.sorted { $0.upvoteCount > $1.upvoteCount }
        case .priority:
            return matching.sorted { $0.priority.weight > $1.priority.weight }
        }
    }

    /// Complaints reported by one student (for "My Reports").
    func issues(reportedBy userId: String?) -> [Issue] {
        guard let userId else { return [] }
        return issues.filter { $0.reportedBy == userId }
    }

    /// Complaints assigned to one staff member (for the staff screens).
    func issues(assignedTo userId: String?) -> [Issue] {
        guard let userId else { return [] }
        return issues.filter { $0.assignedTo == userId }
    }

    func recentIssues(limit: Int = 5) -> [Issue] {
        Array(issues.prefix(limit))
    }

    var statistics: IssueStatistics {
        IssueStatistics(issues: issues)
    }
}
