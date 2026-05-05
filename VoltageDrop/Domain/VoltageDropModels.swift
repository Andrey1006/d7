import Foundation

enum ConductorMaterial: String, CaseIterable, Identifiable, Codable {
    case copper = "Cu"
    case aluminum = "Al"

    var id: String { rawValue }

    var resistivity: Double {
        switch self {
        case .copper: 0.0175
        case .aluminum: 0.0282
        }
    }

    var tempAlpha: Double {
        switch self {
        case .copper: 0.00393
        case .aluminum: 0.00403
        }
    }
}

enum PhaseSystem: String, CaseIterable, Identifiable, Codable {
    case singlePhase = "1Φ"
    case threePhase = "3Φ"

    var id: String { rawValue }
}

enum LoadInputMode: String, CaseIterable, Identifiable, Codable {
    case current = "I"
    case power = "P"

    var id: String { rawValue }
}

struct VoltageDropInput: Codable, Equatable {
    var systemVoltage: Double
    var phase: PhaseSystem
    var loadMode: LoadInputMode

    var currentA: Double
    var powerW: Double
    var powerFactor: Double

    var lengthM: Double
    var areaMM2: Double
    var material: ConductorMaterial

    var allowedDropPercent: Double
}

struct VoltageDropResult: Equatable {
    var dropV: Double
    var dropPercent: Double
    var loadVoltageV: Double
    var lossW: Double

    enum Severity: Equatable {
        case ok, warning, critical
    }

    var severity: Severity
}

struct LinePoint: Identifiable, Equatable {
    let id = UUID()
    let distanceM: Double
    let dropV: Double
    let voltageV: Double
    let lossW: Double
}

