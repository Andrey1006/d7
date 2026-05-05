import Foundation

struct VDSettings: Codable, Equatable {
    var allowedDropPercentDefault: Double
    var warningMultiplier: Double
    var criticalMultiplier: Double
    var profileSteps: Int
    var voltagePresets: [Double]
    var conductorTemperatureC: Double
    var useReactance: Bool
    var reactanceOhmPerKm: Double

    static let `default` = VDSettings(
        allowedDropPercentDefault: 3,
        warningMultiplier: 1.0,
        criticalMultiplier: 1.5,
        profileSteps: 20,
        voltagePresets: [12, 24, 110, 230, 400],
        conductorTemperatureC: 20,
        useReactance: false,
        reactanceOhmPerKm: 0.08
    )
}

struct VDVariant: Identifiable, Codable, Equatable {
    var id: UUID
    var createdAt: Date
    var name: String
    var input: VoltageDropInput
}

struct VDLine: Identifiable, Codable, Equatable {
    var id: UUID
    var createdAt: Date
    var name: String
    var input: VoltageDropInput
}

struct VDProject: Identifiable, Codable, Equatable {
    var id: UUID
    var createdAt: Date
    var title: String
    var notes: String
    var lines: [VDLine]
}

