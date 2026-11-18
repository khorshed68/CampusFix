//
//  RegisterView.swift
//  CampusFix
//
//  Students register here. There is NO role picker: every new account is a
//  student. Admins are promoted manually in the Firebase console (see README).
//

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel

    @State private var fullName = ""
    @State private var email = ""
    @State private var studentId = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Spacer()
                    CampusFixLogo(size: 96)
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Create your account")
                        .font(.title.bold())
                        .foregroundStyle(AppTheme.navy)
                    Text("Join CampusFix to report and track campus problems.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                VStack(spacing: 16) {
                    AppTextField(title: "Full Name", iconName: "person.fill", text: $fullName,
                                 capitalization: .words, contentType: .name)
                    AppTextField(title: "University Email", iconName: "envelope.fill", text: $email,
                                 keyboard: .emailAddress, capitalization: .never,
                                 contentType: .emailAddress)
                    AppTextField(title: "Student ID", iconName: "number", text: $studentId,
                                 keyboard: .asciiCapable, capitalization: .characters)
                    AppTextField(title: "Password", iconName: "lock.fill", text: $password,
                                 isSecure: true, contentType: .newPassword)
                    AppTextField(title: "Confirm Password", iconName: "lock.rotation", text: $confirmPassword,
                                 isSecure: true, contentType: .newPassword)

                    if !password.isEmpty && password.count < AppConstants.minPasswordLength {
                        Text("At least \(AppConstants.minPasswordLength) characters required.")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if !confirmPassword.isEmpty && password != confirmPassword {
                        Text("Passwords do not match.")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if let error = authViewModel.errorMessage {
                        MessageBanner(message: error) { authViewModel.errorMessage = nil }
                    }

                    PrimaryButton(title: "Register", iconName: "person.badge.plus",
                                  isLoading: authViewModel.isWorking) {
                        hideKeyboard()
                        Task {
                            await authViewModel.register(name: fullName, email: email,
                                                         studentId: studentId, password: password,
                                                         confirmPassword: confirmPassword)
                            // On success the root view switches to the dashboard automatically.
                        }
                    }
                }
                .cardStyle(padding: 20)
            }
            .padding(20)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Register")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { authViewModel.errorMessage = nil }
    }
}
