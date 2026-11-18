//
//  ImageUploadService.swift
//  CampusFix
//
//  Uploads complaint photos to ImgBB (free image hosting) and returns
//  the public image URL. That URL is saved in Firestore (issues/{id}.imageURL).
//
//  Why ImgBB? Firebase Storage needs the paid Blaze plan on new projects.
//
//  Flow:  UIImage -> resize + JPEG -> multipart POST to https://api.imgbb.com/1/upload
//         -> JSON response (decoded with JSONDecoder + Codable) -> data.url
//
//  The API key is NOT in the source code. It comes from the git-ignored
//  .env file -> Config/CampusFix.xcconfig -> Config/Info.plist (ImgBBAPIKey).
//

import UIKit

enum ImageUploadError: LocalizedError {
    case missingAPIKey
    case compressionFailed
    case imageTooLarge
    case network(String)
    case server(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Image upload is not configured (ImgBB API key missing). See README → Image hosting."
        case .compressionFailed:
            return "The selected image could not be processed. Please choose another photo."
        case .imageTooLarge:
            return "The image is too large. Please choose a smaller photo (max 5 MB)."
        case .network(let message):
            return "Image upload failed: \(message)"
        case .server(let message):
            return "Image host rejected the upload: \(message)"
        case .invalidResponse:
            return "Image upload failed: unexpected response from the image host."
        }
    }
}

/// LAB TOPIC Protocols: the rest of the app depends on this protocol, not on
/// ImgBB directly, so the image host could be swapped without touching ViewModels.
protocol ImageHostingService {
    func uploadImage(_ image: UIImage, userId: String) async throws -> URL
}

/// Codable model of ImgBB's JSON response (only the fields we need).
/// Success: { "data": { "url": "https://i.ibb.co/...", ... }, "success": true, "status": 200 }
/// Error:   { "error": { "message": "..." }, "success": false, "status": 400 }
private struct ImgBBResponse: Decodable {
    struct ImageData: Decodable {
        let url: String
    }
    struct APIError: Decodable {
        let message: String
    }
    let data: ImageData?
    let success: Bool
    let error: APIError?
}

final class ImgBBService: ImageHostingService {
    private let endpoint = URL(string: "https://api.imgbb.com/1/upload")!

    /// Reads the key injected into Info.plist at build time.
    private var apiKey: String? {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "ImgBBAPIKey") as? String else {
            return nil
        }
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        // An unresolved "$(IMGBB_API_KEY)" means the .env file was not found at build time.
        guard !trimmed.isEmpty, !trimmed.hasPrefix("$(") else { return nil }
        return trimmed
    }

    func uploadImage(_ image: UIImage, userId: String) async throws -> URL {
        guard let apiKey else { throw ImageUploadError.missingAPIKey }

        // 1. Resize + compress (fast uploads, small files)
        guard let jpegData = image.resized(maxDimension: 1600).jpegData(compressionQuality: 0.7) else {
            throw ImageUploadError.compressionFailed
        }
        guard jpegData.count <= AppConstants.maxImageBytes else {
            throw ImageUploadError.imageTooLarge
        }

        // 2. Build a multipart/form-data request: fields "key", "name" and the "image" file
        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "key", value: apiKey)]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.timeoutInterval = 60

        let boundary = "CampusFix-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let fileName = "campusfix_\(userId)_\(UUID().uuidString)"
        request.httpBody = makeMultipartBody(boundary: boundary,
                                             fields: ["name": fileName],
                                             fileField: "image",
                                             fileName: "\(fileName).jpg",
                                             mimeType: "image/jpeg",
                                             fileData: jpegData)

        // 3. Send it (async/await)
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw ImageUploadError.network(error.localizedDescription)
        }

        // 4. Decode the JSON response
        guard let decoded = try? JSONDecoder().decode(ImgBBResponse.self, from: data) else {
            throw ImageUploadError.invalidResponse
        }
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard decoded.success, (200..<300).contains(statusCode),
              let urlString = decoded.data?.url, let url = URL(string: urlString) else {
            throw ImageUploadError.server(decoded.error?.message ?? "HTTP \(statusCode)")
        }
        // firestore.rules only accepts ImgBB image URLs, so check it here too.
        guard urlString.hasPrefix(AppConstants.imageHostURLPrefix) else {
            throw ImageUploadError.invalidResponse
        }
        return url
    }

    /// Builds the raw bytes of a multipart/form-data body.
    private func makeMultipartBody(boundary: String,
                                   fields: [String: String],
                                   fileField: String,
                                   fileName: String,
                                   mimeType: String,
                                   fileData: Data) -> Data {
        var body = Data()
        let lineBreak = "\r\n"

        for (name, value) in fields {
            body.append(Data("--\(boundary)\(lineBreak)".utf8))
            body.append(Data("Content-Disposition: form-data; name=\"\(name)\"\(lineBreak)\(lineBreak)".utf8))
            body.append(Data("\(value)\(lineBreak)".utf8))
        }

        body.append(Data("--\(boundary)\(lineBreak)".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"\(fileField)\"; filename=\"\(fileName)\"\(lineBreak)".utf8))
        body.append(Data("Content-Type: \(mimeType)\(lineBreak)\(lineBreak)".utf8))
        body.append(fileData)
        body.append(Data(lineBreak.utf8))
        body.append(Data("--\(boundary)--\(lineBreak)".utf8))
        return body
    }
}
