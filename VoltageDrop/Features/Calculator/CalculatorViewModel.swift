import Combine
import Foundation

@MainActor
final class CalculatorViewModel: ObservableObject {
    @Published var input: VoltageDropInput = .init(
        systemVoltage: 230,
        phase: .singlePhase,
        loadMode: .current,
        currentA: 16,
        powerW: 2000,
        powerFactor: 0.95,
        lengthM: 30,
        areaMM2: 2.5,
        material: .copper,
        allowedDropPercent: 3
    )

    @Published private(set) var result: VoltageDropResult = .init(
        dropV: 0,
        dropPercent: 0,
        loadVoltageV: 0,
        lossW: 0,
        severity: .ok
    )

    @Published private(set) var profile: [LinePoint] = []
    @Published private(set) var selectedPoint: LinePoint? = nil

    private(set) var settings: VDSettings = .default

    init() {
        recalc()
    }

    func updateSettings(_ settings: VDSettings) {
        self.settings = settings
        if input.allowedDropPercent <= 0 {
            input.allowedDropPercent = settings.allowedDropPercentDefault
        }
        recalc()
    }

    func recalc() {
        let evaluated = VoltageDropCalculator.evaluate(input: input, settings: settings)
        result = evaluated.result
        profile = evaluated.profile
        if let selectedPoint {
            self.selectedPoint = nearestPoint(to: selectedPoint.distanceM)
        }
    }

    func selectDistance(_ distanceM: Double?) {
        guard let distanceM else {
            selectedPoint = nil
            return
        }
        selectedPoint = nearestPoint(to: distanceM)
    }

    private func nearestPoint(to distanceM: Double) -> LinePoint? {
        guard !profile.isEmpty else { return nil }
        return profile.min(by: { abs($0.distanceM - distanceM) < abs($1.distanceM - distanceM) })
    }
}

