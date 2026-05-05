import SwiftUI

enum VDColor {
    static let background = Color(hex: 0xF8FAFC)
    static let title = Color(hex: 0x1F2A44)
    static let secondary = Color(hex: 0x6B7280)

    static let accent = Color(hex: 0x3B82F6)
    static let ok = Color(hex: 0x22C55E)
    static let warning = Color(hex: 0xF59E0B)
    static let critical = Color(hex: 0xEF4444)

    static let border = Color.black.opacity(0.10)
    static let surface = Color.white
    static let surfaceMuted = Color.black.opacity(0.03)
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

