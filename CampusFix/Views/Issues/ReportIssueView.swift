//
//  ReportIssueView.swift
//  CampusFix
//
//  The complaint submission form.
//  Buildings and categories come from campus_data.json (JSON parsing).
//

import SwiftUI

struct ReportIssueView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var viewModel = ReportIssueViewModel()
    @Binding var selectedTab: StudentTab

    // Form input (@State – owned by this screen)
    @State private var title = ""
    @State private var description = ""
    @State private var category = ""
    @State private var building = ""
    @State private var location = ""
    @State private var priority: IssuePriority = .medium
    @State private var selectedImage: UIImage?

    // Sheet / dialog visibility (@State)
    @State private var isShowingPhotoOptions = false
    @State private var imagePickerSource: ImagePicker.Source?
    @State private var isShowingSuccess = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if let warning = viewModel.campusDataWarning {
                        MessageBanner(message: warning, kind: .warning)
                    }

                    detailsSection
                    locationSection
                    prioritySection
                    photoSection

                    if let error = viewModel.errorMessage {
                        MessageBanner(message: error) { viewModel.errorMessage = nil }
                    }

                    PrimaryButton(title: viewModel.isSubmitting ? viewModel.progressMessage : "Submit Complaint",
                                  iconName: "paperplane.fill",
                                  isLoading: viewModel.isSubmitting) {
                        submit()
                    }
                }
                .padding(AppTheme.padding)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Report an Issue")
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") { hideKeyboard() }
                    }
                }
            }
            .onAppear {
                viewModel.loadCampusData()   // decode campus_data.json
            }
            // Photo source choice
            .confirmationDialog("Add a photo", isPresented: $isShowingPhotoOptions, titleVisibility: .visible) {
                if ImagePicker.isCameraAvailable {
                    Button("Take Photo") { imagePickerSource = .camera }
                }
                Button("Choose from Library") { imagePickerSource = .photoLibrary }
                Button("Cancel", role: .cancel) { }
            }
            // The UIKit image picker (delegate pattern) in a sheet
            .sheet(isPresented: Binding(
                get: { imagePickerSource != nil },
                set: { if !$0 { imagePickerSource = nil } }
            )) {
                ImagePicker(source: imagePickerSource ?? .photoLibrary, selectedImage: $selectedImage)
                    .ignoresSafeArea()
            }
            .alert("Complaint submitted", isPresented: $isShowingSuccess) {
                Button("View My Reports") { selectedTab = .myReports }
                Button("Report Another", role: .cancel) { }
            } message: {
                Text("Thank you! Your complaint has been saved and is now visible to administrators. You can track its status in My Reports.")
            }
        }
    }

    // MARK: - Form sections

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            formHeader("What's the problem?", iconName: "text.bubble.fill")

            AppTextField(title: "Issue Title", iconName: "textformat", text: $title)
            Text("\(title.count)/\(AppConstants.maxTitleLength)")
                .font(.caption2)
                .foregroundStyle(title.count > AppConstants.maxTitleLength ? .red : AppTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .trailing)

            VStack(alignment: .leading, spacing: 6) {
                Text("Description")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                TextField("Describe the problem in detail…", text: $description, axis: .vertical)
                    .lineLimit(4...8)
                    .padding(14)
                    .background(AppTheme.background)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius, style: .continuous)
                            .stroke(AppTheme.lightBlue, lineWidth: 1)
                    )
            }

            MenuPickerField(title: "Category", iconName: CategoryIcon.name(for: category),
                            options: viewModel.categories, selection: $category)
        }
        .cardStyle()
    }

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            formHeader("Where is it?", iconName: "mappin.circle.fill")
            MenuPickerField(title: "Building", iconName: "building.2.fill",
                            options: viewModel.buildings, selection: $building)
            AppTextField(title: "Specific Location", iconName: "location.fill", text: $location)
        }
        .cardStyle()
    }

    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            formHeader("How urgent is it?", iconName: "flag.fill")
            Picker("Priority", selection: $priority) {
                ForEach(IssuePriority.allCases) { level in
                    Text(level.title).tag(level)
                }
            }
            .pickerStyle(.segmented)
            HStack(spacing: 6) {
                BadgeView(item: priority)
                Text(priorityHint)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .cardStyle()
    }

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            formHeader("Photo (optional)", iconName: "camera.fill")

            if let selectedImage {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius, style: .continuous))
                    Button {
                        self.selectedImage = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .black.opacity(0.6))
                    }
                    .padding(8)
                    .accessibilityLabel("Remove photo")
                }
                PrimaryButton(title: "Change Photo", iconName: "arrow.triangle.2.circlepath",
                              style: .outlined) {
                    isShowingPhotoOptions = true
                }
            } else {
                Button {
                    isShowingPhotoOptions = true
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 30))
                        Text("Add a photo of the problem")
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundStyle(AppTheme.navy)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
                    .background(AppTheme.lightBlue.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius, style: .continuous)
                            .strokeBorder(AppTheme.skyBlue, style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                    )
                }
            }
        }
        .cardStyle()
    }

    private func formHeader(_ text: String, iconName: String) -> some View {
        Label(text, systemImage: iconName)
            .font(.headline)
            .foregroundStyle(AppTheme.navy)
    }

    private var priorityHint: String {
        switch priority {
        case .low: return "Minor inconvenience"
        case .medium: return "Should be fixed soon"
        case .high: return "Affects classes or many students"
        case .critical: return "Safety risk – needs urgent action"
        }
    }

    // MARK: - Actions

    private func submit() {
        hideKeyboard()
        guard let reporter = authViewModel.currentUser else {
            viewModel.errorMessage = "You must be logged in to report an issue."
            return
        }
        let draft = IssueDraft(title: title, description: description, category: category,
                               building: building, location: location, priority: priority)
        Task {
            let saved = await viewModel.submit(draft, image: selectedImage, reporter: reporter)
            if saved {
                resetForm()
                isShowingSuccess = true   // shown ONLY when Firestore confirmed the save
            }
        }
    }

    private func resetForm() {
        title = ""
        description = ""
        category = ""
        building = ""
        location = ""
        priority = .medium
        selectedImage = nil
    }
}
