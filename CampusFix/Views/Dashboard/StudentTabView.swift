//
//  StudentTabView.swift
//  CampusFix
//
//  The student's bottom navigation bar.
//

import SwiftUI

enum StudentTab: Hashable {
    case home, issues, report, myReports, profile
}

struct StudentTabView: View {
    /// LAB TOPIC @StateObject: this view CREATES the IssueViewModel and keeps
    /// it alive while the student is logged in. Child tabs receive the SAME
    /// instance with @ObservedObject.
    @StateObject private var issueViewModel = IssueViewModel()

    /// The selected tab. Passed to children as a @Binding so, for example,
    /// the dashboard's "Report an Issue" button can switch tabs.
    @State private var selectedTab: StudentTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            StudentDashboardView(issueViewModel: issueViewModel, selectedTab: $selectedTab)
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(StudentTab.home)

            AllIssuesView(issueViewModel: issueViewModel, title: "All Issues")
                .tabItem { Label("Issues", systemImage: "list.bullet.rectangle.fill") }
                .tag(StudentTab.issues)

            ReportIssueView(selectedTab: $selectedTab)
                .tabItem { Label("Report", systemImage: "plus.circle.fill") }
                .tag(StudentTab.report)

            MyReportsView(issueViewModel: issueViewModel, selectedTab: $selectedTab)
                .tabItem { Label("My Reports", systemImage: "doc.text.fill") }
                .tag(StudentTab.myReports)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
                .tag(StudentTab.profile)
        }
        // LAB TOPIC onAppear / onDisappear: start the Firestore listener when the
        // student area appears and remove it when it is taken off screen (logout).
        .onAppear {
            issueViewModel.startListening()
            issueViewModel.loadCategories()
        }
        .onDisappear {
            issueViewModel.stopListening()
        }
    }
}
