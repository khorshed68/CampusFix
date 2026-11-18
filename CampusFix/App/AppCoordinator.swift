//
//  AppCoordinator.swift
//  CampusFix
//
//  The root view. Decides WHICH part of the app to show:
//
//    Splash  ->  Firebase setup screen (if GoogleService-Info.plist is missing)
//            ->  Login               (signed out)
//            ->  Student tab bar     (role == student)
//            ->  Staff tab bar       (role == staff)
//            ->  Admin tab bar       (role == admin)
//
//  The role comes from Firestore (users/{uid}.role), never from the UI.
//

import SwiftUI

struct AppCoordinator: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var isShowingSplash = true

    var body: some View {
        ZStack {
            if isShowingSplash {
                SplashView()
                    .transition(.opacity)
            } else if !FirebaseService.isConfigured {
                FirebaseSetupRequiredView()
            } else {
                sessionContent
                    .transition(.opacity)
            }
        }
        .task {
            // Start watching Firebase Auth right away (restores saved sessions).
            authViewModel.startSessionMonitoring()
            // Keep the splash visible briefly so the brand is seen.
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation(.easeInOut(duration: 0.4)) {
                isShowingSplash = false
            }
        }
    }

    @ViewBuilder
    private var sessionContent: some View {
        switch authViewModel.sessionState {
        case .loading:
            LoadingView(message: "Checking your session…")
        case .signedOut:
            LoginView()
        case .profileUnavailable(let message):
            ProfileUnavailableView(errorMessage: message)
        case .signedIn(let user):
            // Role-based navigation: each role gets its own dashboard.
            switch user.role {
            case .student: StudentTabView()
            case .staff: StaffTabView()
            case .admin: AdminTabView()
            }
        }
    }
}

/// Shown when the user is logged in but their Firestore profile is missing.
private struct ProfileUnavailableView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    let errorMessage: String?

    var body: some View {
        VStack(spacing: 18) {
            CampusFixLogo(size: 72)
            if let errorMessage {
                Text("We couldn't load your profile")
                    .font(.headline)
                    .foregroundStyle(AppTheme.navy)
                MessageBanner(message: errorMessage)
            } else {
                ProgressView()
                Text("Preparing your profile…")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            PrimaryButton(title: "Log Out", iconName: "rectangle.portrait.and.arrow.right",
                          style: .outlined) {
                authViewModel.logout()
            }
            .frame(maxWidth: 220)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background)
    }
}

/// Shown (instead of crashing) when GoogleService-Info.plist was not added.
/// This is NOT a fake demo mode: the app simply cannot work without Firebase.
private struct FirebaseSetupRequiredView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Spacer()
                    CampusFixLogo(size: 72)
                    Spacer()
                }
                Text("Firebase setup required")
                    .font(.title2.bold())
                    .foregroundStyle(AppTheme.navy)
                Text("CampusFix stores accounts, complaints and photos in Firebase. The file GoogleService-Info.plist was not found in the app.")
                    .foregroundStyle(AppTheme.textSecondary)
                VStack(alignment: .leading, spacing: 10) {
                    Label("Create a Firebase project at console.firebase.google.com", systemImage: "1.circle.fill")
                    Label("Add an iOS app with the bundle ID used in Xcode", systemImage: "2.circle.fill")
                    Label("Download GoogleService-Info.plist", systemImage: "3.circle.fill")
                    Label("Drag it into the CampusFix folder in Xcode", systemImage: "4.circle.fill")
                    Label("Run the app again", systemImage: "5.circle.fill")
                }
                .font(.subheadline)
                .cardStyle()
                Text("Full steps are in README.md → Firebase Setup.")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(24)
        }
        .background(AppTheme.background)
    }
}
