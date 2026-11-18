//
//  ReportIssueViewModel.swift
//  CampusFix
//
//  Logic for the "Report an Issue" form:
//   - loads buildings & categories from campus_data.json (JSON parsing)
//   - validates the form
//   - uploads the photo to ImgBB (free image hosting) and gets its public URL
//   - saves the complaint (including that URL) to Firestore
//

import UIKit

/// The values typed into the form, collected into one struct at submit time.
struct IssueDraft {
    var title: String
    var description: String
    var category: String
    var building: String
    var location: String
    var priority: IssuePriority
}

@MainActor
final class ReportIssueViewModel: ObservableObject {
    @Published private(set) var buildings: [String] = []
    @Published private(set) var categories: [String] = []
    @Published private(set) var campusDataWarning: String?

    @Published private(set) var isSubmitting = false
    @Published private(set) var progressMessage = ""
    @Published var errorMessage: String?

    private let firestoreService = FirestoreService()
    /// Typed as the protocol, so another image host could be plugged in later.
    private let imageService: ImageHostingService = ImgBBService()

    // MARK: - JSON

    /// Decodes campus_data.json. If it is missing or invalid we fall back
    /// to safe defaults AND tell the user, instead of crashing.
    func loadCampusData() {
        guard buildings.isEmpty else { return }
        do {
            let data = try JSONService.shared.loadCampusData()
            buildings = data.buildings
            categories = data.categories
            campusDataWarning = nil
        } catch {
            buildings = CampusData.fallback.buildings
            categories = CampusData.fallback.categories
            campusDataWarning = "Campus list could not be loaded (\(error.localizedDescription)). Default options are shown."
        }
    }

    // MARK: - Validation

    func validate(_ draft: IssueDraft) -> String? {
        let title = draft.title.trimmed
        if title.isEmpty { return "Please enter an issue title." }
        if title.count > AppConstants.maxTitleLength {
            return "Title must be \(AppConstants.maxTitleLength) characters or fewer."
        }
        if draft.description.trimmed.count < AppConstants.minDescriptionLength {
            return "Please describe the problem (at least \(AppConstants.minDescriptionLength) characters)."
        }
        if draft.category.isEmpty { return "Please select a category." }
        if draft.building.isEmpty { return "Please select a building." }
        if draft.location.trimmed.isEmpty { return "Please enter the specific location (e.g. Room 304)." }
        return nil
    }

    // MARK: - Submit

    /// Returns true only if the complaint was really saved in Firestore.
    func submit(_ draft: IssueDraft, image: UIImage?, reporter: AppUser) async -> Bool {
        errorMessage = nil
        if let problem = validate(draft) {
            errorMessage = problem
            return false
        }
        guard let reporterId = reporter.id else {
            errorMessage = "You must be logged in to report an issue."
            return false
        }
        guard reporter.can(.reportIssue) else {
            errorMessage = "Only students can report complaints."
            return false
        }

        isSubmitting = true
        defer {
            isSubmitting = false
            progressMessage = ""
        }

        var uploadedImageURL: URL?
        do {
            // Step 1 (optional): upload the photo to ImgBB and get its public URL
            if let image {
                progressMessage = "Uploading photo…"
                uploadedImageURL = try await imageService.uploadImage(image, userId: reporterId)
            }

            // Step 2: save the complaint document
            progressMessage = "Saving complaint…"
            let issue = Issue(title: draft.title.trimmed,
                              description: draft.description.trimmed,
                              category: draft.category,
                              building: draft.building,
                              location: draft.location.trimmed,
                              priority: draft.priority,
                              imageURL: uploadedImageURL?.absoluteString,
                              reportedBy: reporterId,
                              reporterName: reporter.name)
            try await firestoreService.createIssue(issue)
            return true
        } catch {
            // Note: if the photo uploaded but saving the complaint failed, the photo
            // stays on ImgBB (its API has no delete call). Nothing is saved in Firestore.
            errorMessage = error.localizedDescription
            return false
        }
    }
}
