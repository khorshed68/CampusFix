//
//  Extensions.swift
//  CampusFix
//
//  Small helpers added to existing types.
//

import SwiftUI
import UIKit

// MARK: - String helpers

extension String {
    /// Removes spaces and new lines at both ends.
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Simple email format check (something@something.domain).
    var isValidEmail: Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return range(of: pattern, options: .regularExpression) != nil
    }
}

// MARK: - Date helpers

extension Date {
    /// "2 hours ago", "3 days ago"
    var relativeDescription: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    /// "12 Nov 2026, 3:45 PM"
    var fullDescription: String {
        formatted(date: .abbreviated, time: .shortened)
    }
}

extension Optional where Wrapped == Date {
    /// Server timestamps are nil for a moment right after creating a document
    /// (until the server confirms), so we show "Just now" instead.
    var relativeOrJustNow: String {
        self?.relativeDescription ?? "Just now"
    }
}

// MARK: - Category icons

/// Maps a category name from campus_data.json to an SF Symbol.
/// Unknown categories get a generic icon, so new JSON entries never break the UI.
enum CategoryIcon {
    static func name(for category: String) -> String {
        switch category.lowercased() {
        case "electrical": return "bolt.fill"
        case "furniture": return "chair.lounge.fill"
        case "projector": return "videoprojector.fill"
        case "water supply": return "drop.fill"
        case "internet": return "wifi"
        case "washroom": return "toilet.fill"
        case "air conditioning", "fan": return "fan.fill"
        case "lighting": return "lightbulb.fill"
        default: return "wrench.adjustable.fill"
        }
    }
}

// MARK: - View styling

extension View {
    /// White rounded card with a soft shadow – used on every screen.
    func cardStyle(padding: CGFloat = AppTheme.padding) -> some View {
        self
            .padding(padding)
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
    }

    /// Hides the keyboard (used by "Done" buttons and when tapping outside a field).
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}

// MARK: - UIImage helpers

extension UIImage {
    /// Shrinks large camera photos before upload (saves data and time).
    func resized(maxDimension: CGFloat) -> UIImage {
        let largestSide = max(size.width, size.height)
        guard largestSide > maxDimension else { return self }
        let scale = maxDimension / largestSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        return UIGraphicsImageRenderer(size: newSize).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
