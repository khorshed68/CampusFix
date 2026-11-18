//
//  CreateStaffAccountView.swift
//  CampusFix
//
//  Trusted provisioning: only an admin can create Maintenance Staff accounts.
//  The admin stays logged in (see AuthService.createAccountForAnotherUser).
//

import SwiftUI

struct CreateStaffAccountView: View {
    @ObservedObject var viewModel: UserManagementViewModel

    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var staffId = ""
    @State private var temporaryPassword = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Label("New accounts get the Maintenance Staff role. Share the temporary password with the staff member privately; they can log in immediately.",
                          systemImage: "info.circle.fill")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.textSecondary)

                    AppTextField(title: "Full Name", iconName: "person.fill", text: $name,
                                 capitalization: .words, contentType: .name)
                    AppTextField(title: "Work Email", iconName: "envelope.fill", text: $email,
                                 keyboard: .emailAddress, capitalization: .never)
                    AppTextField(title: "Staff ID", iconName: "number", text: $staffId,
                                 keyboard: .asciiCapable, capitalization: .characters)
                    AppTextField(title: "Temporary Password", iconName: "key.fill", text: $temporaryPassword,
                                 isSecure: true, contentType: .newPassword)

                    if let error = viewModel.errorMessage {
                        MessageBanner(message: error) { viewModel.errorMessage = nil }
                    }

                    PrimaryButton(title: "Create Staff Account", iconName: "person.badge.plus",
                                  isLoading: viewModel.isWorking) {
                        hideKeyboard()
                        Task {
                            let created = await viewModel.createStaffAccount(name: name, email: email,
                                                                             staffId: staffId,
                                                                             password: temporaryPassword,
                                                                             by: authViewModel.currentUser)
                            if created { dismiss() }
                        }
                    }
                }
                .cardStyle(padding: 20)
                .padding(AppTheme.padding)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("New Staff Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { viewModel.errorMessage = nil }
            .interactiveDismissDisabled(viewModel.isWorking)
        }
    }
}
