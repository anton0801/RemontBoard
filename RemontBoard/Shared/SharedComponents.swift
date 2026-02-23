import SwiftUI

// MARK: - FormField
struct FormField: View {
    let label       : String
    let placeholder : String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionLabel(text: label)
            TextField(placeholder, text: $text)
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(AppColors.cardBackground)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(AppColors.accentBlue.opacity(0.35), lineWidth: 1))
        }
        .padding(.horizontal)
    }
}

// MARK: - SectionLabel
struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(AppColors.accentBlue)
            .textCase(.uppercase)
            .tracking(0.5)
    }
}

// MARK: - YellowButton
struct YellowButton: View {
    let title    : String
    let disabled : Bool
    let action   : () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(disabled ? AppColors.accent.opacity(0.4) : AppColors.accent)
                .cornerRadius(16)
                .shadow(color: disabled ? .clear : AppColors.accent.opacity(0.35), radius: 12, y: 6)
        }
        .disabled(disabled)
        .scaleButtonStyle()
    }
}

// MARK: - EmptyStateView
struct EmptyStateView: View {
    let icon    : String
    let message : String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 42))
                .foregroundColor(AppColors.secondaryText)
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(AppColors.secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 44)
    }
}

// MARK: - PickerField
struct PickerField<T: Hashable & RawRepresentable>: View where T.RawValue == String {
    let label     : String
    @Binding var selection: T
    let options   : [T]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionLabel(text: label)
            Picker("", selection: $selection) {
                ForEach(options, id: \.self) { opt in
                    Text(opt.rawValue).tag(opt)
                }
            }
            .pickerStyle(.menu)
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(AppColors.cardBackground)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10)
                .stroke(AppColors.accentBlue.opacity(0.35), lineWidth: 1))
        }
        .padding(.horizontal)
    }
}

// MARK: - SegmentButton
struct SegmentButton: View {
    let title      : String
    let isSelected : Bool
    let action     : () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: isSelected ? .bold : .regular))
                .foregroundColor(isSelected ? AppColors.background : .white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? AppColors.accent : AppColors.cardBackground)
                .cornerRadius(20)
        }
        .scaleButtonStyle()
    }
}

// MARK: - StatChip
struct StatChip: View {
    let icon  : String
    let value : String
    let label : String
    let color : Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(AppColors.cardBackground)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14)
            .stroke(color.opacity(0.3), lineWidth: 1))
    }
}

// MARK: - RenovationTypeBadge
struct RenovationTypeBadge: View {
    let type: RenovationType

    var color: Color {
        switch type {
        case .cosmetic: return AppColors.accentBlue
        case .major:    return AppColors.warning
        case .designer: return .purple
        }
    }

    var body: some View {
        Text(type.rawValue)
            .font(.system(size: 8, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color)
            .cornerRadius(6)
    }
}

// MARK: - TierBadge
struct TierBadge: View {
    let tier: MaterialTier
    var body: some View {
        Text(tier.rawValue)
            .font(.system(size: 8, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(tier.color.opacity(0.75))
            .cornerRadius(4)
    }
}
