//
//  JSONService.swift
//  CampusFix
//
//  LAB TOPIC: JSON Parsing
//  Loads a JSON file from the app bundle and decodes it with JSONDecoder
//  into Codable Swift models.
//
//  Steps:
//   1. Find the file in the bundle         -> Bundle.main.url(forResource:withExtension:)
//   2. Read the raw bytes                  -> Data(contentsOf:)
//   3. Convert bytes into Swift structs    -> JSONDecoder().decode(Type.self, from: data)
//   4. Throw a clear error if anything fails, so the UI can show a message.
//

import Foundation

/// Every way loading JSON can fail, with a human-readable message.
enum JSONServiceError: LocalizedError {
    case fileNotFound(String)
    case unreadable(String)
    case invalidFormat(String, String)
    case emptyData(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let name):
            return "\(name).json was not found in the app bundle."
        case .unreadable(let name):
            return "\(name).json could not be read."
        case .invalidFormat(let name, let detail):
            return "\(name).json has an invalid format: \(detail)"
        case .emptyData(let name):
            return "\(name).json does not contain any items."
        }
    }
}

struct JSONService {
    static let shared = JSONService()

    /// Generic loader: works for ANY Decodable type (CampusData, [SampleIssue], ...).
    func load<T: Decodable>(_ type: T.Type, fromFile fileName: String) throws -> T {
        // 1. Locate the file
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            throw JSONServiceError.fileNotFound(fileName)
        }

        // 2. Read it
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw JSONServiceError.unreadable(fileName)
        }

        // 3. Decode it
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch let DecodingError.keyNotFound(key, _) {
            throw JSONServiceError.invalidFormat(fileName, "missing key '\(key.stringValue)'")
        } catch let DecodingError.typeMismatch(_, context) {
            throw JSONServiceError.invalidFormat(fileName, context.debugDescription)
        } catch {
            throw JSONServiceError.invalidFormat(fileName, error.localizedDescription)
        }
    }

    /// Loads buildings and categories for the selection menus.
    func loadCampusData() throws -> CampusData {
        let campusData = try load(CampusData.self, fromFile: AppConstants.campusDataFile)
        guard !campusData.buildings.isEmpty, !campusData.categories.isEmpty else {
            throw JSONServiceError.emptyData(AppConstants.campusDataFile)
        }
        return campusData
    }

    /// Loads demo complaints used by the admin seed tool.
    func loadSampleIssues() throws -> [SampleIssue] {
        let samples = try load([SampleIssue].self, fromFile: AppConstants.sampleIssuesFile)
        guard !samples.isEmpty else {
            throw JSONServiceError.emptyData(AppConstants.sampleIssuesFile)
        }
        return samples
    }
}
