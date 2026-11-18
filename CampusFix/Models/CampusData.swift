//
//  CampusData.swift
//  CampusFix
//
//  Codable models that match Resources/campus_data.json and
//  Resources/sample_issues.json exactly. JSONDecoder uses the property
//  names to find the matching JSON keys.
//

import Foundation

/// Matches campus_data.json:
/// { "buildings": [ ... ], "categories": [ ... ] }
struct CampusData: Codable {
    let buildings: [String]
    let categories: [String]

    /// Used only if campus_data.json is missing or broken, so the
    /// app keeps working and the user sees a warning instead of a crash.
    static let fallback = CampusData(
        buildings: ["Main Campus"],
        categories: ["Other"]
    )
}

/// One entry of sample_issues.json (used by the admin "seed sample data" tool).
struct SampleIssue: Codable {
    let title: String
    let description: String
    let category: String
    let building: String
    let location: String
    let priority: IssuePriority   // decoded from "Low" / "Medium" / "High" / "Critical"
}
