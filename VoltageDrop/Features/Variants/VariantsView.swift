import SwiftUI

struct VariantsView: View {
    @EnvironmentObject private var store: AppStore

    @State private var selection = Set<UUID>()
    @State private var showGenerator = false

    var body: some View {
        VDScreen("📏 Variants") {
            VDCard("Variants") {
                if store.variants.isEmpty {
                    Text("No saved variants yet. Save one from the ⚡ tab.")
                        .font(VDTypography.caption)
                        .foregroundStyle(VDColor.secondary)
                } else {
                    VStack(spacing: 8) {
                        ForEach(store.variants) { v in
                            NavigationLink {
                                VariantDetailView(variantId: v.id)
                                    .environmentObject(store)
                            } label: {
                                variantRow(v)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            VDCard("Compare (2–4)") {
                let chosen = store.variants.filter { selection.contains($0.id) }
                if chosen.count < 2 {
                    Text("Select at least two variants to compare.")
                        .font(VDTypography.caption)
                        .foregroundStyle(VDColor.secondary)
                } else {
                    compareBlock(chosen)
                }
            }

            HStack(spacing: 12) {
                VDPrimaryButton("Generator", icon: "wand.and.stars") {
                    showGenerator = true
                }
                VDPrimaryButton("Clear selection", icon: "xmark") {
                    selection.removeAll()
                }
            }
        }
        .sheet(isPresented: $showGenerator) {
            generatorSheet()
        }
    }

    private func variantRow(_ v: VDVariant) -> some View {
        let isSelected = selection.contains(v.id)
        let eval = VoltageDropCalculator.evaluate(input: v.input, settings: store.settings).result
        let tone: VDMetric.VDTone = {
            switch eval.severity {
            case .ok: .ok
            case .warning: .warning
            case .critical: .critical
            }
        }()

        return HStack(spacing: 10) {
            Button {
                if isSelected {
                    selection.remove(v.id)
                } else if selection.count < 4 {
                    selection.insert(v.id)
                }
            } label: {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isSelected ? VDColor.accent : VDColor.secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(v.name)
                    .font(VDTypography.headline)
                    .foregroundStyle(VDColor.title)
                Text("ΔU \(fmt(eval.dropPercent))% • \(v.input.material.rawValue) \(fmt(v.input.areaMM2))mm² • \(fmt(v.input.lengthM))m")
                    .font(VDTypography.caption)
                    .foregroundStyle(VDColor.secondary)
            }

            Spacer(minLength: 0)

            Text(severityLabel(eval.severity))
                .font(VDTypography.caption)
                .foregroundStyle(tone.color)

            Button(role: .destructive) {
                store.deleteVariant(v.id)
                selection.remove(v.id)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
            .foregroundStyle(VDColor.critical)
        }
        .vdFullWidthCell()
        .padding(10)
        .background(VDColor.surfaceMuted)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(tone.color.opacity(isSelected ? 0.6 : 0.25), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func compareBlock(_ items: [VDVariant]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(items) { v in
                let r = VoltageDropCalculator.evaluate(input: v.input, settings: store.settings).result
                HStack {
                    Text(v.name)
                        .font(VDTypography.headline)
                        .foregroundStyle(VDColor.title)
                    Spacer(minLength: 0)
                    Text("ΔU \(fmt(r.dropPercent))%")
                        .font(VDTypography.metricSmall)
                        .foregroundStyle(color(for: r.severity))
                }
                .padding(.vertical, 6)
                .overlay(Rectangle().frame(height: 1).foregroundStyle(VDColor.border), alignment: .bottom)
            }

            let best = items
                .map { (v: $0, r: VoltageDropCalculator.evaluate(input: $0.input, settings: store.settings).result) }
                .min(by: { $0.r.dropPercent < $1.r.dropPercent })

            if let best {
                Text("✅ Best by ΔU: \(best.v.name) (\(fmt(best.r.dropPercent))%)")
                    .font(VDTypography.caption)
                    .foregroundStyle(VDColor.secondary)
            }
        }
    }

    private func generatorSheet() -> some View {
        NavigationStack {
            VariantGeneratorView()
                .environmentObject(store)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { showGenerator = false }
                    }
                }
        }
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

    private func severityLabel(_ s: VoltageDropResult.Severity) -> String {
        switch s {
        case .ok: "✅"
        case .warning: "⚠️"
        case .critical: "🛑"
        }
    }
}

#Preview {
    NavigationStack { VariantsView().environmentObject(AppStore()) }
}

