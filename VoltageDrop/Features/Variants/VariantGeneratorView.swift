import SwiftUI

struct VariantGeneratorView: View {
    @EnvironmentObject private var store: AppStore

    @State private var base = VoltageDropInput(
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

    @State private var includeOnlyPassing = true

    private let areas: [Double] = [1.5, 2.5, 4, 6, 10, 16, 25, 35, 50, 70, 95, 120]

    var body: some View {
        VDScreen("Variant generator") {
            VDCard("Base") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Show passing only", isOn: $includeOnlyPassing)
                        .font(VDTypography.caption)
                        .foregroundStyle(VDColor.secondary)

                    HStack(spacing: 12) {
                        Picker("Material", selection: $base.material) {
                            ForEach(ConductorMaterial.allCases) { m in
                                Text(m.rawValue).tag(m)
                            }
                        }
                        .pickerStyle(.segmented)

                        Picker("Phase", selection: $base.phase) {
                            ForEach(PhaseSystem.allCases) { p in
                                Text(p.rawValue).tag(p)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
            }

            VDCard("Variants by area") {
                VStack(spacing: 8) {
                    ForEach(areas, id: \.self) { a in
                        let input = makeInput(area: a)
                        let r = VoltageDropCalculator.evaluate(input: input, settings: store.settings).result
                        let passes = r.dropPercent <= input.allowedDropPercent
                        if !includeOnlyPassing || passes {
                            HStack {
                                Text("\(fmt(a)) mm²")
                                    .font(VDTypography.headline)
                                    .foregroundStyle(VDColor.title)
                                Spacer(minLength: 0)
                                Text("ΔU \(fmt(r.dropPercent))%")
                                    .font(VDTypography.metricSmall)
                                    .foregroundStyle(color(for: r.severity))
                                Button("Save") {
                                    store.upsertVariant(
                                        name: "\(base.material.rawValue) \(fmt(a))mm² • \(fmt(base.lengthM))m",
                                        input: input
                                    )
                                }
                                .font(VDTypography.caption)
                                .foregroundStyle(VDColor.accent)
                            }
                            .vdFullWidthCell()
                            .padding(10)
                            .background(VDColor.surfaceMuted)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(color(for: r.severity).opacity(0.25), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                }
            }
        }
        .onAppear {
            base.allowedDropPercent = store.settings.allowedDropPercentDefault
        }
    }

    private func makeInput(area: Double) -> VoltageDropInput {
        var i = base
        i.areaMM2 = area
        i.allowedDropPercent = base.allowedDropPercent
        return i
    }

    private func fmt(_ v: Double) -> String {
        let f = NumberFormatter()
        f.locale = .current
        f.numberStyle = .decimal
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 0
        return f.string(from: NSNumber(value: v)) ?? "\(v)"
    }

    private func color(for s: VoltageDropResult.Severity) -> Color {
        switch s {
        case .ok: VDColor.ok
        case .warning: VDColor.warning
        case .critical: VDColor.critical
        }
    }
}

#Preview {
    NavigationStack { VariantGeneratorView().environmentObject(AppStore()) }
}

