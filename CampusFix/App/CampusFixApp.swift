//
//  CampusFixApp.swift
//  CampusFix
//
//  The app's entry point (@main).
//

import SwiftUI

@main
struct CampusFixApp: App {
    /// LAB TOPIC @StateObject: the App CREATES and OWNS the AuthViewModel,
    /// so it lives for the whole lifetime of the app.
    @StateObject private var authViewModel = AuthViewModel()

    init() {
        // Must run before any Firebase service is used.
        FirebaseService.configureIfPossible()
    }

    var body: some Scene {
        WindowGroup {
            AppCoordinator()
                // LAB TOPIC @EnvironmentObject: every child screen can read
                // the same AuthViewModel without passing it manually.
                .environmentObject(authViewModel)
                .tint(AppTheme.navy)
        }
    }
}
