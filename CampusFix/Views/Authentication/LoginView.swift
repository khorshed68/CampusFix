//
//  LoginView.swift
//  CampusFix
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel

    // LAB TOPIC @State: form input owned by this screen
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        // LAB TOPIC NavigationStack: Login -> Register
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    header

                    VStack(spacing: 16) {
                        AppTextField(title: "Email", iconName: "envelope.fill", text: $email,
                                     keyboard: .emailAddress, capitalization: .never,
                                     contentType: .emailAddress)
                        AppTextField(title: "Password", iconName: "lock.fill", text: $password,
                                     isSecure: true, contentType: .password)

                        if let error = authViewModel.errorMessage {
                            MessageBanner(message: error) { authViewModel.errorMessage = nil }
                        }

                        PrimaryButton(title: "Log In", iconName: "arrow.right.circle.fill",
                                      isLoading: authViewModel.isWorking) {
                            hideKeyboard()
                            Task { await authViewModel.login(email: email, password: password) }
                        }
                    }
                    .cardStyle(padding: 20)

                    HStack(spacing: 4) {
                        Text("New to CampusFix?")
                            .foregroundStyle(AppTheme.textSecondary)
                        NavigationLink("Create an account") {
                            RegisterView()
                        }
                        .fontWeight(.semibold)
                    }
                    .font(.subheadline)

                    Text("Administrators log in with the account assigned to them.")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(AppTheme.background.ignoresSafeArea())
            .onAppear {
                authViewModel.errorMessage = nil   // don't show old errors
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            CampusFixLogo(size: 160)
                .padding(.top, 12)
            Text("Welcome back")
                .font(.largeTitle.bold())
                .foregroundStyle(AppTheme.navy)
            Text("Log in to report and track campus issues")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
        }
    }
}
