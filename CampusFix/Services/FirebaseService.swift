//
//  FirebaseService.swift
//  CampusFix
//
//  Starts Firebase when the app launches.
//
//  FirebaseApp.configure() reads GoogleService-Info.plist. If that file is
//  missing, Firebase would crash the app, so we check first and show a
//  "Firebase setup required" screen instead.
//

import Foundation
import FirebaseCore

enum FirebaseService {
    /// True only after FirebaseApp.configure() has run successfully.
    private(set) static var isConfigured = false

    static func configureIfPossible() {
        guard !isConfigured else { return }
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            print("⚠️ GoogleService-Info.plist not found. Firebase is NOT configured.")
            return
        }
        FirebaseApp.configure()
        isConfigured = true
    }
}
