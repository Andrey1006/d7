import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore

    @State private var allowedText = ""
    @State private var warningText = ""
    @State private var criticalText = ""
    @State private var stepsText = ""
    @State private var presetsText = ""
    @State private var tempText = ""
    @State private var useReactance = false
    @State private var reactanceText = ""

    var body: some View {
        VDScreen("⚙️ Settings") {
            VDCard("Thresholds") {
                VStack(alignment: .leading, spacing: 12) {
                    VDField(title: "Default allowed ΔU", placeholder: "3", text: $allowedText, keyboard: .decimalPad, trailing: "%")
                    VDField(title: "Warning multiplier", placeholder: "1.0", text: $warningText, keyboard: .decimalPad, trailing: "×")
                    VDField(title: "Critical multiplier", placeholder: "1.5", text: $criticalText, keyboard: .decimalPad, trailing: "×")

                    VDPrimaryButton("Save", icon: "checkmark") {
                        apply()
                    }
                }
            }

            VDCard("Visualization") {
                VStack(alignment: .leading, spacing: 12) {
                    VDField(title: "Profile steps", placeholder: "20", text: $stepsText, keyboard: .numberPad, trailing: "")
                    VDField(title: "Voltage presets (comma-separated)", placeholder: "12,24,230,400", text: $presetsText, keyboard: .numbersAndPunctuation, trailing: "V")

                    VDPrimaryButton("Apply", icon: "slider.horizontal.3") {
                        apply()
                    }
                }
            }

            VDCard("Accuracy") {
                VStack(alignment: .leading, spacing: 12) {
                    VDField(title: "Conductor temperature", placeholder: "20", text: $tempText, keyboard: .decimalPad, trailing: "°C")

                    Toggle("Include reactance X", isOn: $useReactance)
                        .font(VDTypography.caption)
                        .foregroundStyle(VDColor.secondary)

                    VDField(title: "X (Ω/km)", placeholder: "0.08", text: $reactanceText, keyboard: .decimalPad, trailing: "Ω/km")

                    VDPrimaryButton("Save accuracy", icon: "checkmark") {
                        apply()
                    }
                }
            }

            VDCard("Reference") {
                VStack(alignment: .leading, spacing: 10) {
                    Text("• 1Φ: ΔU = 2·I·(R·cosφ + X·sinφ)")
                    Text("• 3Φ: ΔU = √3·I·(R·cosφ + X·sinφ)")
                    Text("• R = ρ·L/A (Ω), ρ: Ω·mm²/m")
                }
                .font(VDTypography.caption)
                .foregroundStyle(VDColor.secondary)
            }
        }
        .onAppear { seed() }
    }

    private func seed() {
        let s = store.settings
        allowedText = raw(s.allowedDropPercentDefault)
        warningText = raw(s.warningMultiplier)
        criticalText = raw(s.criticalMultiplier)
        stepsText = String(s.profileSteps)
        presetsText = s.voltagePresets.map { raw($0) }.joined(separator: ",")
        tempText = raw(s.conductorTemperatureC)
        useReactance = s.useReactance
        reactanceText = raw(s.reactanceOhmPerKm)
    }

    private func apply() {
        var s = store.settings
        if let v = parseDouble(allowedText) { s.allowedDropPercentDefault = v }
        if let w = parseDouble(warningText) { s.warningMultiplier = w }
        if let c = parseDouble(criticalText) { s.criticalMultiplier = c }
        if let st = Int(stepsText.trimmingCharacters(in: .whitespacesAndNewlines)), st > 5, st <= 200 {
            s.profileSteps = st
        }

        let presets = presetsText
            .split(separator: ",")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .compactMap(parseDouble)
            .filter { $0 > 0 }

        if !presets.isEmpty {
            s.voltagePresets = Array(presets.prefix(12))
        }

        if let t = parseDouble(tempText) { s.conductorTemperatureC = t }
        s.useReactance = useReactance
        if let x = parseDouble(reactanceText) { s.reactanceOhmPerKm = x }

        store.settings = s
        seed()
    }

    private func parseDouble(_ s: String) -> Double? {
        Double(s.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private func raw(_ value: Double) -> String {
        let f = NumberFormatter()
        f.locale = .current
        f.numberStyle = .decimal
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

#Preview {
    NavigationStack { SettingsView().environmentObject(AppStore()) }
}

