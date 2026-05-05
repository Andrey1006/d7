import Charts
import SwiftUI

struct SavedLineDetailView: View {
    @EnvironmentObject private var store: AppStore
    let projectTitle: String
    let line: VDLine

    @State private var selected: LinePoint? = nil

    var body: some View {
        let evaluated = VoltageDropCalculator.evaluate(input: line.input, settings: store.settings)
        let result = evaluated.result
        let profile = evaluated.profile

        return VDScreen(line.name) {
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
                    VDMetric(icon: "⚠️", title: "ΔU limit", value: "\(fmt(line.input.allowedDropPercent))%", subtitle: nil, tone: .neutral)
                }
            }

            VDCard("ΔU chart by length") {
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

            VDCard("Inputs") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Project: \(projectTitle)").font(VDTypography.caption).foregroundStyle(VDColor.secondary)
                    Text("L \(fmt(line.input.lengthM)) m • A \(fmt(line.input.areaMM2)) mm² • \(line.input.material.rawValue) • \(line.input.phase.rawValue)")
                        .font(VDTypography.caption)
                        .foregroundStyle(VDColor.secondary)
                }
                .vdFullWidthCell()
            }
        }
        .vdHidesTabBarOnPush()
    }

    private func nearest(_ points: [LinePoint], to d: Double) -> LinePoint? {
        guard !points.isEmpty else { return nil }
        return points.min(by: { abs($0.distanceM - d) < abs($1.distanceM - d) })
    }

    private func fmt(_ v: Double) -> String {
        let f = NumberFormatter()
        f.locale = .current
        f.numberStyle = .decimal
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 0
        return f.string(from: NSNumber(value: v)) ?? "\(v)"
    }
}

#Preview {
    NavigationStack {
        SavedLineDetailView(projectTitle: "Demo", line: .init(id: UUID(), createdAt: .now, name: "Line", input: .init(systemVoltage: 230, phase: .singlePhase, loadMode: .current, currentA: 16, powerW: 0, powerFactor: 0.95, lengthM: 30, areaMM2: 2.5, material: .copper, allowedDropPercent: 3)))
            .environmentObject(AppStore())
    }
}

