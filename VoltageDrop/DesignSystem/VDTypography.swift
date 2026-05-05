import SwiftUI

enum VDTypography {
    static func title(_ size: CGFloat = 20) -> Font { .system(size: size, weight: .semibold, design: .rounded) }
    static let headline: Font = .system(size: 16, weight: .semibold, design: .rounded)
    static let body: Font = .system(size: 15, weight: .regular, design: .rounded)
    static let caption: Font = .system(size: 12, weight: .regular, design: .rounded)

    static let metric: Font = .system(size: 22, weight: .semibold, design: .monospaced)
    static let metricSmall: Font = .system(size: 16, weight: .semibold, design: .monospaced)
}

