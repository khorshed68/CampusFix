//
//  AppConstants.swift
//  CampusFix
//
//  One place for colours, sizes and Firebase names, so every
//  screen looks consistent and nothing is mistyped.
//

import SwiftUI

enum AppTheme {
    // Brand colours – sampled from the CampusFix logo (Assets: CampusFixLogo)
    static let navy = Color(red: 0.004, green: 0.145, blue: 0.376)      // #012560 logo navy
    static let logoBackground = Color(red: 0.004, green: 0.125, blue: 0.314) // #012050 logo tile edge
    static let lightBlue = Color(red: 0.859, green: 0.914, blue: 0.973) // #DBE9F8
    static let skyBlue = Color(red: 0.000, green: 0.475, blue: 0.937)   // #0079EF logo pin blue
    static let background = Color(red: 0.957, green: 0.965, blue: 0.980) // #F4F6FA
    static let card = Color.white
    static let textSecondary = Color(red: 0.420, green: 0.455, blue: 0.518)

    // Shapes and spacing
    static let cornerRadius: CGFloat = 16
    static let smallCornerRadius: CGFloat = 10
    static let padding: CGFloat = 16

    static let headerGradient = LinearGradient(
        colors: [logoBackground, navy, skyBlue],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

enum AppConstants {
    static let appName = "CampusFix"
    static let tagline = "Report. Track. Improve Your Campus."

    // Firestore collection names
    enum Collections {
        static let users = "users"
        static let issues = "issues"
        static let votes = "votes"
    }

    // Complaint photos are hosted on ImgBB; Firestore only stores the public URL.
    // firestore.rules accepts only URLs that start with this prefix.
    static let imageHostURLPrefix = "https://i.ibb.co/"

    // Local JSON resource files (in Resources/)
    static let campusDataFile = "campus_data"
    static let sampleIssuesFile = "sample_issues"

    // Validation limits
    static let minPasswordLength = 6
    static let maxTitleLength = 80
    static let minDescriptionLength = 10
    static let maxImageBytes = 5 * 1024 * 1024   // 5 MB after compression (ImgBB allows up to 32 MB)
}
