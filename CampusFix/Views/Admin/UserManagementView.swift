//
//  UserManagementView.swift
//  CampusFix
//
//  Admin "User Management" screen: list all accounts, filter by role,
//  create staff accounts, change roles, activate / deactivate users.
//

import SwiftUI

struct UserManagementView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var viewModel = UserManagementViewModel()

    @State private var roleFilter: Role? = nil
    @State private var searchText = ""
    @State private var isShowingCreateStaff = false
    @State private var editingUser: AppUser?

    var body: some View {
        NavigationStack {
            let visibleUsers = viewModel.users(withRole: roleFilter, matching: searchText)

            List {
                Section {
                    HStack(spacing: 10) {
                        ForEach(Role.allCases) { role in
                            VStack(spacing: 4) {
                                Text("\(viewModel.count(of: role))")
                                    .font(.title3.bold())
                                    .foregroundStyle(role.color)
                                Text(role == .staff ? "Staff" : role.displayName + "s")
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .frame(maxWidth: .infinity)
                            .cardStyle(padding: 10)
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                    Picker("Role", selection: $roleFilter) {
                        Text("All").tag(Role?.none)
                        Text("Students").tag(Role?.some(.student))
                        Text("Staff").tag(Role?.some(.staff))
                        Text("Admins").tag(Role?.some(.admin))
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                    if let success = viewModel.successMessage {
                        MessageBanner(message: success, kind: .success) { viewModel.successMessage = nil }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                    if let error = viewModel.errorMessage {
                        MessageBanner(message: error) { viewModel.errorMessage = nil }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                }

                Section {
                    if viewModel.isLoading {
                        ProgressView().frame(maxWidth: .infinity).padding(.vertical, 30)
                    } else if visibleUsers.isEmpty {
                        EmptyStateView(iconName: "person.2",
                                       title: "No users found",
                                       message: "Try a different search or role filter.")
                    } else {
                        ForEach(visibleUsers) { user in
                            Button {
                                editingUser = user
                            } label: {
                                UserRow(user: user, isCurrentUser: user.id == authViewModel.currentUser?.id)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppTheme.background.ignoresSafeArea())
            .searchable(text: $searchText, prompt: "Search name, email, ID")
            .navigationTitle("User Management")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isShowingCreateStaff = true
                    } label: {
                        Label("New Staff Account", systemImage: "person.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingCreateStaff) {
                CreateStaffAccountView(viewModel: viewModel)
            }
            .sheet(item: $editingUser) { user in
                UserAccessSheet(user: user, viewModel: viewModel)
            }
            .onAppear { viewModel.startListening() }
            .onDisappear { viewModel.stopListening() }
        }
    }
}

private struct UserRow: View {
    let user: AppUser
    let isCurrentUser: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: user.role.iconName)
                .foregroundStyle(user.role.color)
                .frame(width: 38, height: 38)
                .background(user.role.color.opacity(0.12))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(user.name).font(.subheadline.weight(.semibold))
                    if isCurrentUser {
                        Text("You").font(.caption2).foregroundStyle(AppTheme.textSecondary)
                    }
                }
                Text(user.email)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                BadgeView(item: user.role, compact: true)
                if !user.isAccountActive {
                    Text("Deactivated")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.red)
                }
            }
        }
        .contentShape(Rectangle())
        .opacity(user.isAccountActive ? 1 : 0.6)
    }
}

// MARK: - Change role / activation

private struct UserAccessSheet: View {
    let user: AppUser
    @ObservedObject var viewModel: UserManagementViewModel

    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var role: Role
    @State private var isActive: Bool

    init(user: AppUser, viewModel: UserManagementViewModel) {
        self.user = user
        self.viewModel = viewModel
        _role = State(initialValue: user.role)
        _isActive = State(initialValue: user.isAccountActive)
    }

    private var canEdit: Bool { viewModel.canEdit(user, actor: authViewModel.currentUser) }
    private var hasChanges: Bool { role != user.role || isActive != user.isAccountActive }

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    LabeledContent("Name", value: user.name)
                    LabeledContent("Email", value: user.email)
                    LabeledContent(user.role.idFieldLabel, value: user.studentId.isEmpty ? "—" : user.studentId)
                }

                if canEdit {
                    Section {
                        Picker("Role", selection: $role) {
                            Text(Role.student.displayName).tag(Role.student)
                            Text(Role.staff.displayName).tag(Role.staff)
                        }
                        Toggle("Account active", isOn: $isActive)
                    } header: {
                        Text("Access")
                    } footer: {
                        Text("Deactivated users are signed out of the app immediately and are blocked by the security rules. Admin privileges can only be granted in the Firebase Console.")
                    }
                } else {
                    Section {
                        Label(user.id == authViewModel.currentUser?.id
                              ? "You can't change your own account here."
                              : "Administrator accounts are managed in the Firebase Console.",
                              systemImage: "lock.fill")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }

                if let error = viewModel.errorMessage {
                    Section { MessageBanner(message: error) }
                }
            }
            .navigationTitle("Manage User")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                if canEdit {
                    ToolbarItem(placement: .confirmationAction) {
                        if viewModel.isWorking {
                            ProgressView()
                        } else {
                            Button("Save") {
                                Task {
                                    if await viewModel.updateAccess(for: user, role: role, isActive: isActive,
                                                                    by: authViewModel.currentUser) {
                                        dismiss()
                                    }
                                }
                            }
                            .fontWeight(.semibold)
                            .disabled(!hasChanges)
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
