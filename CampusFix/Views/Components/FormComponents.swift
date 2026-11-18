//
//  FormComponents.swift
//  CampusFix
//
//  Reusable input fields and buttons used by every form.
//

import SwiftUI

// MARK: - AppTextField

/// A labelled text field.
/// LAB TOPIC @Binding: the parent screen OWNS the text (@State) and this
/// child view can read AND change it through the binding.
struct AppTextField: View {
    let title: String
    let iconName: String
    @Binding var text: String
    var isSecure = false
    var keyboard: UIKeyboardType = .default
    var capitalization: TextInputAutocapitalization = .sentences
    var contentType: UITextContentType? = nil

    @State private var isRevealed = false   // local UI state: show/hide password

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)

            HStack(spacing: 10) {
                Image(systemName: iconName)
                    .foregroundStyle(AppTheme.navy)
                    .frame(width: 20)

                Group {
                    if isSecure && !isRevealed {
                        SecureField(title, text: $text)
                    } else {
                        TextField(title, text: $text)
                            .keyboardType(keyboard)
                            .textInputAutocapitalization(capitalization)
                    }
                }
                .textContentType(contentType)
                .autocorrectionDisabled()

                if isSecure {
                    Button {
                        isRevealed.toggle()
                    } label: {
                        Image(systemName: isRevealed ? "eye.slash" : "eye")
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .accessibilityLabel(isRevealed ? "Hide password" : "Show password")
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(AppTheme.background)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius, style: .continuous)
                    .stroke(AppTheme.lightBlue, lineWidth: 1)
            )
        }
    }
}

// MARK: - PrimaryButton

struct PrimaryButton: View {
    enum Style { case filled, outlined, destructive }

    let title: String
    var iconName: String? = nil
    var style: Style = .filled
    var isLoading = false
    var isDisabled = false
    let action: () -> Void           // closure: what to do when tapped

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(style == .filled ? .white : AppTheme.navy)
                } else if let iconName {
                    Image(systemName: iconName)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .foregroundStyle(foreground)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius, style: .continuous)
                    .stroke(style == .outlined ? AppTheme.navy : .clear, lineWidth: 1.5)
            )
            .opacity(isDisabled ? 0.5 : 1)
        }
        .disabled(isLoading || isDisabled)
    }

    private var foreground: Color {
        switch style {
        case .filled, .destructive: return .white
        case .outlined: return AppTheme.navy
        }
    }

    private var background: Color {
        switch style {
        case .filled: return AppTheme.navy
        case .outlined: return .clear
        case .destructive: return .red
        }
    }
}

// MARK: - Option picker (menu style)

/// A dropdown menu for choosing one string, e.g. building or category.
/// Uses @Binding so the parent form owns the selected value.
struct MenuPickerField: View {
    let title: String
    let iconName: String
    let options: [String]
    @Binding var selection: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)

            Menu {
                ForEach(options, id: \.self) { option in
                    Button(option) { selection = option }
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: iconName)
                        .foregroundStyle(AppTheme.navy)
                        .frame(width: 20)
                    Text(selection.isEmpty ? "Select \(title.lowercased())" : selection)
                        .foregroundStyle(selection.isEmpty ? AppTheme.textSecondary : .primary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
                .background(AppTheme.background)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius, style: .continuous)
                        .stroke(AppTheme.lightBlue, lineWidth: 1)
                )
            }
        }
    }
}
