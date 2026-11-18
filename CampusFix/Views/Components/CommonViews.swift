//
//  CommonViews.swift
//  CampusFix
//
//  Small reusable building blocks: stat cards, empty states, banners,
//  loading indicators, section headers, and the remote image view.
//

import SwiftUI

// MARK: - StatCard (dashboard numbers)

struct StatCard: View {
    let title: String
    let value: Int
    let iconName: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: iconName)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 34, height: 34)
                .background(color.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            Text("\(value)")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 14)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - SectionHeader

struct SectionHeader: View {
    let title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(AppTheme.navy)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.skyBlue)
            }
        }
    }
}

// MARK: - EmptyStateView

struct EmptyStateView: View {
    let iconName: String
    let title: String
    let message: String
    var buttonTitle: String? = nil
    var buttonAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 44))
                .foregroundStyle(AppTheme.skyBlue)
                .padding(.bottom, 4)
            Text(title)
                .font(.headline)
                .foregroundStyle(AppTheme.navy)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
            if let buttonTitle, let buttonAction {
                PrimaryButton(title: buttonTitle, action: buttonAction)
                    .frame(maxWidth: 240)
                    .padding(.top, 6)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Banners

struct MessageBanner: View {
    enum Kind { case error, success, warning }

    let message: String
    var kind: Kind = .error
    var onDismiss: (() -> Void)? = nil

    private var color: Color {
        switch kind {
        case .error: return .red
        case .success: return .green
        case .warning: return .orange
        }
    }

    private var iconName: String {
        switch kind {
        case .error: return "exclamationmark.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: iconName)
            Text(message)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                }
                .accessibilityLabel("Dismiss message")
            }
        }
        .foregroundStyle(color)
        .padding(12)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius, style: .continuous))
    }
}

// MARK: - Loading

struct LoadingView: View {
    var message = "Loading…"

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)
                .tint(AppTheme.navy)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background)
    }
}

// MARK: - Remote image (public ImgBB URL)

struct IssueImageView: View {
    let urlString: String?

    var body: some View {
        if let urlString, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    placeholder { ProgressView() }
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    placeholder {
                        Label("Image could not be loaded", systemImage: "photo.badge.exclamationmark")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                @unknown default:
                    placeholder { EmptyView() }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 220)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
        }
    }

    private func placeholder<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        ZStack {
            AppTheme.lightBlue.opacity(0.5)
            content()
        }
    }
}

// MARK: - Brand identity
//
// The official CampusFix logo lives in Assets.xcassets:
//   CampusFixLogo  – full logo (building, pin, name, tagline), transparent corners
//   CampusFixMark  – emblem only (building + pin), for small places
//   AppIcon        – the same artwork as the home-screen icon
// Use these components everywhere so the identity stays consistent.

/// The full CampusFix logo (rounded navy tile with name and tagline).
struct CampusFixLogo: View {
    var size: CGFloat = 96

    var body: some View {
        Image("CampusFixLogo")
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: size, height: size)
            .shadow(color: AppTheme.navy.opacity(0.25), radius: size * 0.06, y: size * 0.03)
            .accessibilityLabel("\(AppConstants.appName) logo. \(AppConstants.tagline)")
    }
}

/// The emblem only (no text) – readable at small sizes.
struct CampusFixMark: View {
    var height: CGFloat = 32

    var body: some View {
        Image("CampusFixMark")
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: height * 0.22, style: .continuous))
            .accessibilityHidden(true)
    }
}

/// Navigation-bar title: emblem + "CampusFix". Used by all three dashboards.
struct BrandNavigationTitle: View {
    var body: some View {
        HStack(spacing: 8) {
            CampusFixMark(height: 26)
            HStack(spacing: 0) {
                Text("Campus").foregroundStyle(AppTheme.navy)
                Text("Fix").foregroundStyle(AppTheme.skyBlue)
            }
            .font(.system(size: 18, weight: .heavy, design: .rounded))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(AppConstants.appName)
    }
}
