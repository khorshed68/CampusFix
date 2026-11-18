//
//  EditProfileView.swift
//  CampusFix
//
//  Lets the user change their name and student ID.
//  Email and role cannot be changed here (role is protected by firestore.rules).
//

import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var studentId = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    AppTextField(title: "Full Name", iconName: "person.fill", text: $name,
                                 capitalization: .words, contentType: .name)
                    AppTextField(title: authViewModel.currentUser?.role.idFieldLabel ?? "Student ID",
                                 iconName: "number", text: $studentId,
                                 keyboard: .asciiCapable, capitalization: .characters)

                    Label("Your email and role can only be changed by an administrator.",
                          systemImage: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if let error = authViewModel.errorMessage {
                        MessageBanner(message: error) { authViewModel.errorMessage = nil }
                    }

                    PrimaryButton(title: "Save Changes", iconName: "checkmark",
                                  isLoading: authViewModel.isWorking) {
                        Task {
                            if await authViewModel.updateProfile(name: name, studentId: studentId) {
                                dismiss()
                            }
                        }
                    }
                }
                .cardStyle(padding: 20)
                .padding(AppTheme.padding)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                // Pre-fill the form with the current values.
                authViewModel.errorMessage = nil
                name = authViewModel.currentUser?.name ?? ""
                studentId = authViewModel.currentUser?.studentId ?? ""
            }
        }
    }
}
