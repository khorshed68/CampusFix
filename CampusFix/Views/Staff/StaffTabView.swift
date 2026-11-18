//
//  StaffTabView.swift
//  CampusFix
//
//  Bottom navigation for Maintenance Staff.
//  Shown only when users/{uid}.role == "staff" in Firestore.
//

import SwiftUI

enum StaffTab: Hashable {
    case dashboard, assigned, profile
}

struct StaffTabView: View {
    @StateObject private var issueViewModel = IssueViewModel()
    @State private var selectedTab: StaffTab = .dashboard

    var body: some View {
        TabView(selection: $selectedTab) {
            StaffDashboardView(issueViewModel: issueViewModel, selectedTab: $selectedTab)
                .tabItem { Label("Dashboard", systemImage: "house.fill") }
                .tag(StaffTab.dashboard)

            AssignedComplaintsView(issueViewModel: issueViewModel)
                .tabItem { Label("My Tasks", systemImage: "checklist") }
                .tag(StaffTab.assigned)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
                .tag(StaffTab.profile)
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
