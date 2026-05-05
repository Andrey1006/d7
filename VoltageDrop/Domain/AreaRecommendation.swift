import Foundation

enum AreaRecommendation {
    static let commonAreas: [Double] = [1.5, 2.5, 4, 6, 10, 16, 25, 35, 50, 70, 95, 120, 150, 185, 240]

    static func minimalAreaMeetingLimit(input: VoltageDropInput, settings: VDSettings) -> Double? {
        let base = sanitize(input, settings: settings)
        for a in commonAreas {
            var i = base
            i.areaMM2 = a
            let r = VoltageDropCalculator.evaluate(input: i, settings: settings).result
            if r.dropPercent <= i.allowedDropPercent {
                return a
            }
        }
        return nil
    }

    private static func sanitize(_ input: VoltageDropInput, settings: VDSettings) -> VoltageDropInput {
        var i = input
        if i.allowedDropPercent <= 0 { i.allowedDropPercent = settings.allowedDropPercentDefault }
        if i.systemVoltage <= 0 { i.systemVoltage = 230 }
        if i.lengthM < 0 { i.lengthM = 0 }
        if i.areaMM2 <= 0 { i.areaMM2 = 2.5 }
        if i.powerFactor <= 0 { i.powerFactor = 0.95 }
        return i
    }
}

