//
//  ProfileView.swift
//  CampusFix
//
//  Shows the logged-in user's details. Used by both students and admins.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var isShowingEditSheet = false
    @State private var isShowingLogoutConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                if let user = authViewModel.currentUser {
                    VStack(spacing: 20) {
                        avatar(for: user)

                        VStack(spacing: 12) {
                            ProfileRow(iconName: "person.fill", label: "Name", value: user.name)
                            Divider()
                            ProfileRow(iconName: "envelope.fill", label: "Email", value: user.email)
                            if user.isStudent || !user.studentId.isEmpty {
                                Divider()
                                ProfileRow(iconName: "number", label: user.role.idFieldLabel,
                                           value: user.studentId)
                            }
                            Divider()
                            ProfileRow(iconName: "person.badge.shield.checkmark.fill", label: "Role",
                                       value: user.role.displayName)
                            if let createdAt = user.createdAt {
                                Divider()
                                ProfileRow(iconName: "calendar", label: "Member since",
                                           value: createdAt.formatted(date: .abbreviated, time: .omitted))
                            }
                        }
                        .cardStyle()

                        if let error = authViewModel.errorMessage {
                            MessageBanner(message: error) { authViewModel.errorMessage = nil }
                        }

                        VStack(spacing: 12) {
                            PrimaryButton(title: "Edit Profile", iconName: "pencil", style: .outlined) {
                                isShowingEditSheet = true
                            }
                            PrimaryButton(title: "Log Out", iconName: "rectangle.portrait.and.arrow.right",
                                          style: .destructive) {
                                isShowingLogoutConfirmation = true
                            }
                        }

                        Text("\(AppConstants.appName) v\(appVersion) · \(AppConstants.tagline)")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .padding(AppTheme.padding)
                }
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Profile")
            .sheet(isPresented: $isShowingEditSheet) {
                EditProfileView()
            }
            .confirmationDialog("Log out of CampusFix?", isPresented: $isShowingLogoutConfirmation,
                                titleVisibility: .visible) {
                Button("Log Out", role: .destructive) { authViewModel.logout() }
                Button("Cancel", role: .cancel) { }
            }
        }
    }

    private func avatar(for user: AppUser) -> some View {
        VStack(spacing: 10) {
            Text(initials(of: user.name))
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 92, height: 92)
                .background(Circle().fill(AppTheme.headerGradient))
                .shadow(color: AppTheme.navy.opacity(0.3), radius: 10, y: 5)
            Text(user.name)
                .font(.title2.bold())
                .foregroundStyle(AppTheme.navy)
            BadgeView(item: user.role)
        }
        .padding(.top, 8)
    }

    private func initials(of name: String) -> String {
        let parts = name.split(separator: " ").prefix(2)
        let letters = parts.compactMap { $0.first }.map { String($0) }.joined()
        return letters.isEmpty ? "?" : letters.uppercased()
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

private struct ProfileRow: View {
    let iconName: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Label(label, systemImage: iconName)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
            Spacer(minLength: 16)
            Text(value.isEmpty ? "—" : value)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}
