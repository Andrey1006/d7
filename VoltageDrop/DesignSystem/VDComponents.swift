import SwiftUI

extension View {
    @ViewBuilder
    func vdHidesTabBarOnPush() -> some View {
        self.toolbar(.hidden, for: .tabBar)
    }

    @ViewBuilder
    func vdFullWidthCell(alignment: Alignment = .leading) -> some View {
        self.frame(maxWidth: .infinity, alignment: alignment)
    }
}

struct VDCard<Content: View>: View {
    let title: String?
    let content: Content

    init(_ title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title {
                Text(title)
                    .font(VDTypography.headline)
                    .foregroundStyle(VDColor.title)
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(VDColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(VDColor.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct VDKeyboardDoneToolbar: ViewModifier {
    let enabled: Bool
    @FocusState.Binding var isFocused: Bool

    func body(content: Content) -> some View {
        content
            .toolbar {
                if enabled {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") { isFocused = false }
                    }
                }
            }
    }
}

struct VDMetric: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String?
    let tone: VDTone

    enum VDTone {
        case neutral, ok, warning, critical

        var color: Color {
            switch self {
            case .neutral: VDColor.accent
            case .ok: VDColor.ok
            case .warning: VDColor.warning
            case .critical: VDColor.critical
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(icon)
                Text(title)
                    .font(VDTypography.caption)
                    .foregroundStyle(VDColor.secondary)
                Spacer(minLength: 0)
            }
            Text(value)
                .font(VDTypography.metric)
                .foregroundStyle(VDColor.title)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let subtitle {
                Text(subtitle)
                    .font(VDTypography.caption)
                    .foregroundStyle(tone.color)
            }
            Spacer()
        }
        .padding(14)
        .background(VDColor.surfaceMuted)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(tone.color.opacity(0.35), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct VDPrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon { Image(systemName: icon) }
                Text(title)
            }
            .font(VDTypography.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.white)
        .background(VDColor.accent)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(VDColor.border, lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct VDField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .decimalPad
    var trailing: String? = nil
    var isInvalid: Bool = false
    var isNumeric: Bool = true
    var allowsClear: Bool = true
    var helper: String? = nil

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(VDTypography.caption)
                .foregroundStyle(VDColor.secondary)

            HStack(spacing: 10) {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboard)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(isNumeric ? VDTypography.metricSmall : VDTypography.body)
                    .foregroundStyle(VDColor.title)
                    .focused($isFocused)
                    .submitLabel(.done)
                    .onSubmit { isFocused = false }

                if allowsClear, isFocused, !text.isEmpty {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(VDColor.secondary.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }

                if let trailing {
                    Text(trailing)
                        .font(VDTypography.caption)
                        .foregroundStyle(VDColor.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(VDColor.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(borderColor, lineWidth: 1.25)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            if let helper {
                Text(helper)
                    .font(VDTypography.caption)
                    .foregroundStyle(isInvalid ? VDColor.critical : VDColor.secondary)
            }
        }
        .modifier(VDKeyboardDoneToolbar(enabled: keyboard == .decimalPad || keyboard == .numberPad || keyboard == .numbersAndPunctuation, isFocused: $isFocused))
    }

    private var borderColor: Color {
        if isInvalid { return VDColor.critical.opacity(0.85) }
        if isFocused { return VDColor.accent.opacity(0.65) }
        return VDColor.border
    }
}

struct VDScreen<Content: View>: View {
    let title: String
    let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
        .scrollIndicators(.hidden)
        .background(VDColor.background)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

