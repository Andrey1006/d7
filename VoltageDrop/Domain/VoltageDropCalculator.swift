import Foundation

enum VoltageDropCalculator {
    static func evaluate(input: VoltageDropInput, settings: VDSettings = .default) -> (result: VoltageDropResult, profile: [LinePoint]) {
        let pf = input.powerFactor.clamped(to: 0.1...1.0)
        let sinPhi = sqrt(max(0, 1 - pf * pf))

        let currentA: Double = {
            switch input.loadMode {
            case .current:
                return max(0, input.currentA)
            case .power:
                let p = max(0, input.powerW)
                let u = max(1, input.systemVoltage)
                switch input.phase {
                case .singlePhase:
                    return p / (u * pf)
                case .threePhase:
                    return p / (sqrt(3) * u * pf)
                }
            }
        }()

        let lengthM = max(0, input.lengthM)
        let area = max(0.1, input.areaMM2)
        let rho = input.material.resistivity
        let alpha = input.material.tempAlpha
        let tempC = settings.conductorTemperatureC.clamped(to: -40...200)

        let r20 = rho * lengthM / area
        let rOneWay = r20 * (1 + alpha * (tempC - 20))
        let xOneWay = settings.useReactance ? max(0, settings.reactanceOhmPerKm) * (lengthM / 1000.0) : 0

        let k: Double = (input.phase == .singlePhase) ? 2.0 : sqrt(3.0)
        let dropV = k * currentA * ((rOneWay * pf) + (xOneWay * sinPhi))

        let systemV = max(1, input.systemVoltage)
        let dropPercent = (dropV / systemV) * 100.0
        let loadVoltage = systemV - dropV
        let lossW = currentA * currentA * effectiveLoopResistance(phase: input.phase, oneWayR: rOneWay)

        let severity: VoltageDropResult.Severity = {
            let warn = input.allowedDropPercent * max(1.0, settings.warningMultiplier)
            let crit = input.allowedDropPercent * max(warn, settings.criticalMultiplier)
            if dropPercent <= warn { return .ok }
            if dropPercent <= crit { return .warning }
            return .critical
        }()

        let result = VoltageDropResult(
            dropV: dropV,
            dropPercent: dropPercent,
            loadVoltageV: loadVoltage,
            lossW: lossW,
            severity: severity
        )

        let profile = makeProfile(
            systemV: systemV,
            currentA: currentA,
            phase: input.phase,
            pf: pf,
            sinPhi: sinPhi,
            rho: rho,
            alpha: alpha,
            tempC: tempC,
            xOhmPerKm: settings.useReactance ? max(0, settings.reactanceOhmPerKm) : 0,
            lengthM: lengthM,
            areaMM2: area,
            steps: settings.profileSteps
        )

        return (result, profile)
    }

    private static func effectiveLoopResistance(phase: PhaseSystem, oneWayR: Double) -> Double {
        switch phase {
        case .singlePhase:
            return 2.0 * oneWayR
        case .threePhase:
            return oneWayR
        }
    }

    private static func makeProfile(
        systemV: Double,
        currentA: Double,
        phase: PhaseSystem,
        pf: Double,
        sinPhi: Double,
        rho: Double,
        alpha: Double,
        tempC: Double,
        xOhmPerKm: Double,
        lengthM: Double,
        areaMM2: Double,
        steps: Int
    ) -> [LinePoint] {
        guard lengthM > 0 else {
            return [LinePoint(distanceM: 0, dropV: 0, voltageV: systemV, lossW: 0)]
        }

        let n = min(max(steps, 5), 200)
        let k: Double = (phase == .singlePhase) ? 2.0 : sqrt(3.0)
        return (0...n).map { idx in
            let d = (Double(idx) / Double(n)) * lengthM
            let r20 = rho * d / areaMM2
            let rOneWay = r20 * (1 + alpha * (tempC - 20))
            let xOneWay = max(0, xOhmPerKm) * (d / 1000.0)

            let dropV = k * currentA * ((rOneWay * pf) + (xOneWay * sinPhi))

            let voltage = systemV - dropV
            let loss = currentA * currentA * effectiveLoopResistance(phase: phase, oneWayR: rOneWay)

            return LinePoint(distanceM: d, dropV: dropV, voltageV: voltage, lossW: loss)
        }
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

