import Charts
import SwiftUI

struct VariantDetailView: View {
    @EnvironmentObject private var store: AppStore
    let variantId: UUID

    @State private var selected: LinePoint? = nil

    var body: some View {
        guard let v = store.variants.first(where: { $0.id == variantId }) else {
            return AnyView(
                VDScreen("Variant") {
                    Text("Not found.")
                        .font(VDTypography.caption)
                        .foregroundStyle(VDColor.secondary)
                }
            )
        }

        let evaluated = VoltageDropCalculator.evaluate(input: v.input, settings: store.settings)
        let result = evaluated.result
        let profile = evaluated.profile

        return AnyView(
            VDScreen(v.name) {
                VDCard("KPI") {
                    let tone: VDMetric.VDTone = {
                        switch result.severity {
                        case .ok: .ok
                        case .warning: .warning
                        case .critical: .critical
                        }
                    }()
                    LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
                        VDMetric(icon: "📉", title: "ΔU", value: "\(fmt(result.dropV)) V • \(fmt(result.dropPercent))%", subtitle: nil, tone: tone)
                        VDMetric(icon: "⚡", title: "Load voltage", value: "\(fmt(result.loadVoltageV)) V", subtitle: nil, tone: .neutral)
                        VDMetric(icon: "📏", title: "Loss", value: "\(fmt(result.lossW)) W", subtitle: nil, tone: .neutral)
                        VDMetric(icon: "⚠️", title: "ΔU limit", value: "\(fmt(v.input.allowedDropPercent))%", subtitle: nil, tone: .neutral)
                    }
                }

                VDCard("ΔU chart") {
                    Chart {
                        ForEach(profile) { p in
                            LineMark(x: .value("m", p.distanceM), y: .value("ΔU", p.dropV))
                                .foregroundStyle(VDColor.accent)
                                .interpolationMethod(.catmullRom)
                                .lineStyle(.init(lineWidth: 2))
                        }
                        if let s = selected {
                            RuleMark(x: .value("m", s.distanceM))
                                .foregroundStyle(VDColor.title.opacity(0.35))
                            PointMark(x: .value("m", s.distanceM), y: .value("ΔU", s.dropV))
                                .symbolSize(55)
                                .foregroundStyle(VDColor.title)
                        }
                    }
                    .frame(height: 220)
                    .chartOverlay { proxy in
                        GeometryReader { geo in
                            Rectangle()
                                .fill(Color.clear)
                                .contentShape(Rectangle())
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { value in
                                            let origin = geo[proxy.plotAreaFrame].origin
                                            let x = value.location.x - origin.x
                                            if let d: Double = proxy.value(atX: x) {
                                                selected = nearest(profile, to: d)
                                            }
                                        }
                                )
                        }
                    }
                }

                VDCard("Table") {
                    VStack(spacing: 8) {
                        headerRow()
                        ForEach(profile) { p in
                            row(p)
                                .padding(.horizontal, 8)
                                .background(rowBackground(for: p))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .onTapGesture { selected = p }
                        }
                    }
                }
            }
            .vdHidesTabBarOnPush()
        )
    }

    private func nearest(_ points: [LinePoint], to d: Double) -> LinePoint? {
        guard !points.isEmpty else { return nil }
        return points.min(by: { abs($0.distanceM - d) < abs($1.distanceM - d) })
    }

    private func headerRow() -> some View {
        HStack {
            Text("m").frame(width: 70, alignment: .leading)
            Spacer(minLength: 0)
            Text("ΔU").frame(width: 80, alignment: .trailing)
            Text("U").frame(width: 80, alignment: .trailing)
            Text("loss").frame(width: 80, alignment: .trailing)
        }
        .font(VDTypography.caption)
        .foregroundStyle(VDColor.secondary)
        .padding(.vertical, 6)
        .overlay(Rectangle().frame(height: 1).foregroundStyle(VDColor.border), alignment: .bottom)
    }

    private func row(_ p: LinePoint) -> some View {
        HStack {
            Text(fmt0(p.distanceM))
                .frame(width: 70, alignment: .leading)
                .foregroundStyle(VDColor.title)
            Spacer(minLength: 0)
            Text("\(fmt(p.dropV)) V").frame(width: 80, alignment: .trailing)
            Text("\(fmt(p.voltageV)) V").frame(width: 80, alignment: .trailing)
            Text("\(fmt(p.lossW)) W").frame(width: 80, alignment: .trailing)
        }
        .vdFullWidthCell()
        .font(VDTypography.body.monospaced())
        .foregroundStyle(VDColor.title)
        .padding(.vertical, 4)
    }

    private func rowBackground(for p: LinePoint) -> Color {
        guard let selected else { return Color.clear }
        if abs(selected.distanceM - p.distanceM) < 0.0001 {
            return VDColor.accent.opacity(0.10)
        }
        return Color.clear
    }

    private func fmt(_ v: Double) -> String { VDNumber.format(v, fractionDigits: 2) }
    private func fmt0(_ v: Double) -> String { VDNumber.format(v, fractionDigits: 0) }
}

#Preview {
    NavigationStack { VariantDetailView(variantId: UUID()).environmentObject(AppStore()) }
}

