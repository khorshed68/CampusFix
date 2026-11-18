//
//  AdminTabView.swift
//  CampusFix
//
//  Bottom navigation for administrators.
//  Shown only when users/{uid}.role == "admin" in Firestore.
//

import SwiftUI

enum AdminTab: Hashable {
    case dashboard, manage, users, profile
}

struct AdminTabView: View {
    @StateObject private var issueViewModel = IssueViewModel()
    @State private var selectedTab: AdminTab = .dashboard

    var body: some View {
        TabView(selection: $selectedTab) {
            AdminDashboardView(issueViewModel: issueViewModel, selectedTab: $selectedTab)
                .tabItem { Label("Dashboard", systemImage: "chart.bar.xaxis") }
                .tag(AdminTab.dashboard)

            // Same list screen as students. Opening a complaint as an admin shows
            // the "Assign to Staff" and "Manage Complaint" buttons.
            AllIssuesView(issueViewModel: issueViewModel, title: "Manage Complaints")
                .tabItem { Label("Complaints", systemImage: "slider.horizontal.3") }
                .tag(AdminTab.manage)

            UserManagementView()
                .tabItem { Label("Users", systemImage: "person.2.fill") }
                .tag(AdminTab.users)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
                .tag(AdminTab.profile)
        }
        .onAppear {
            issueViewModel.startListening()
            issueViewModel.loadCategories()
        }
        .onDisappear {
            issueViewModel.stopListening()
        }
    }
}
