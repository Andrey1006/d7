import Charts
import SwiftUI

struct LineAnalysisView: View {
    @EnvironmentObject private var store: AppStore

    @State private var source: Source = .calculator
    @State private var selectedVariantId: UUID? = nil
    @State private var selectedProjectLine: ProjectLineRef? = nil

    @State private var mode: Mode = .dropPercent
    @State private var selected: LinePoint? = nil

    enum Mode: String, CaseIterable, Identifiable {
        case dropV = "ΔU (V)"
        case dropPercent = "ΔU (%)"
        case voltage = "U (V)"
        case loss = "P_loss (W)"

        var id: String { rawValue }
    }

    enum Source: String, CaseIterable, Identifiable {
        case calculator = "⚡ Current inputs"
        case variant = "📏 Variant"
        case projectLine = "🗂️ Project line"

        var id: String { rawValue }
    }

    struct ProjectLineRef: Hashable, Identifiable {
        var id: String { "\(projectId.uuidString)-\(lineId.uuidString)" }
        let projectId: UUID
        let lineId: UUID
    }

    var body: some View {
        VDScreen("📉 Line") {
            VDCard("Chart") {
                Picker("Source", selection: $source) {
                    ForEach(Source.allCases) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
                .pickerStyle(.menu)

                sourcePicker()

                Picker("Mode", selection: $mode) {
                    ForEach(Mode.allCases) { m in
                        Text(m.rawValue).tag(m)
                    }
                }
                .pickerStyle(.segmented)

                let input = resolvedInput()
                let evaluated = VoltageDropCalculator.evaluate(input: input, settings: store.settings)
                let points = evaluated.profile

                Chart {
                    ForEach(points) { p in
                        LineMark(
                            x: .value("m", p.distanceM),
                            y: .value("y", yValue(p, input: input))
                        )
                        .foregroundStyle(VDColor.accent)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(.init(lineWidth: 2))
                    }

                    if let s = selected {
                        RuleMark(x: .value("m", s.distanceM))
                            .foregroundStyle(VDColor.title.opacity(0.35))
                        PointMark(x: .value("m", s.distanceM), y: .value("y", yValue(s, input: input)))
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
                                            selected = nearest(points, to: d)
                                        }
                                    }
                            )
                    }
                }

                if let s = selected {
                    Text("📍 \(formatM(s.distanceM)) m • \(mode.rawValue): \(formatY(yValue(s, input: input)))")
                        .font(VDTypography.caption)
                        .foregroundStyle(VDColor.secondary)
                } else {
                    Text("Drag on the chart to select a point.")
                        .font(VDTypography.caption)
                        .foregroundStyle(VDColor.secondary)
                }
            }

            VDCard("Problem segments") {
                let input = resolvedInput()
                let evaluated = VoltageDropCalculator.evaluate(input: input, settings: store.settings)
                let problems = problemSegments(profile: evaluated.profile, allowed: input.allowedDropPercent, voltage: input.systemVoltage, input: input)

                if problems.isEmpty {
                    Text("✅ No critical segments found.")
                        .font(VDTypography.caption)
                        .foregroundStyle(VDColor.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(problems) { seg in
                            HStack(alignment: .top) {
                                Text(seg.icon)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(formatM(seg.fromM))–\(formatM(seg.toM)) m")
                                        .font(VDTypography.headline)
                                        .foregroundStyle(VDColor.title)
                                    Text(seg.text)
                                        .font(VDTypography.caption)
                                        .foregroundStyle(seg.color)
                                }
                                Spacer(minLength: 0)
                                Button("Fix") {
                                    applyFix(seg.fix)
                                }
                                .font(VDTypography.caption)
                                .foregroundStyle(VDColor.accent)
                            }
                            .padding(10)
                            .background(VDColor.surfaceMuted)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(seg.color.opacity(0.35), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                }
            }

            VDCard("Table") {
                let input = resolvedInput()
                let points = VoltageDropCalculator.evaluate(input: input, settings: store.settings).profile
                VStack(spacing: 8) {
                    headerRow()
                    ForEach(points) { p in
                        row(p)
                            .padding(.horizontal, 8)
                            .background(rowBackground(for: p))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .onTapGesture { selected = p }
                    }
                }
            }
        }
        .onAppear {
            selectedVariantId = store.variants.first?.id
            selectedProjectLine = firstProjectLineRef()
        }
    }

    private func resolvedInput() -> VoltageDropInput {
        switch source {
        case .calculator:
            return store.lastCalculatorInput
        case .variant:
            if let id = selectedVariantId, let v = store.variants.first(where: { $0.id == id }) {
                return v.input
            }
            return store.lastCalculatorInput
        case .projectLine:
            if let ref = selectedProjectLine,
               let p = store.projects.first(where: { $0.id == ref.projectId }),
               let line = p.lines.first(where: { $0.id == ref.lineId }) {
                return line.input
            }
            return store.lastCalculatorInput
        }
    }

    @ViewBuilder
    private func sourcePicker() -> some View {
        switch source {
        case .calculator:
            Text("Source: current inputs from ⚡.")
                .font(VDTypography.caption)
                .foregroundStyle(VDColor.secondary)
        case .variant:
            Picker("Variant", selection: $selectedVariantId) {
                ForEach(store.variants) { v in
                    Text(v.name).tag(Optional(v.id))
                }
            }
            .pickerStyle(.menu)
        case .projectLine:
            Picker("Line", selection: $selectedProjectLine) {
                ForEach(allProjectLineRefs(), id: \.self) { ref in
                    Text(projectLineName(ref)).tag(Optional(ref))
                }
            }
            .pickerStyle(.menu)
        }
    }

    private func projectLineName(_ ref: ProjectLineRef) -> String {
        guard let p = store.projects.first(where: { $0.id == ref.projectId }),
              let line = p.lines.first(where: { $0.id == ref.lineId }) else { return "—" }
        return "\(p.title) • \(line.name)"
    }

    private func allProjectLineRefs() -> [ProjectLineRef] {
        store.projects.flatMap { p in p.lines.map { ProjectLineRef(projectId: p.id, lineId: $0.id) } }
    }

    private func firstProjectLineRef() -> ProjectLineRef? {
        guard let p = store.projects.first, let l = p.lines.first else { return nil }
        return ProjectLineRef(projectId: p.id, lineId: l.id)
    }

    private func yValue(_ p: LinePoint, input: VoltageDropInput) -> Double {
        switch mode {
        case .dropV: p.dropV
        case .dropPercent: (p.dropV / max(1, input.systemVoltage)) * 100.0
        case .voltage: p.voltageV
        case .loss: p.lossW
        }
    }

    private func formatY(_ y: Double) -> String {
        let f = NumberFormatter()
        f.locale = .current
        f.numberStyle = .decimal
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: y)) ?? "\(y)"
    }

    private func formatM(_ m: Double) -> String {
        let f = NumberFormatter()
        f.locale = .current
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: m)) ?? "\(m)"
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
            Text(formatM(p.distanceM))
                .frame(width: 70, alignment: .leading)
                .foregroundStyle(VDColor.title)
            Spacer(minLength: 0)
            Text("\(formatY(p.dropV)) V").frame(width: 80, alignment: .trailing)
            Text("\(formatY(p.voltageV)) V").frame(width: 80, alignment: .trailing)
            Text("\(formatY(p.lossW)) W").frame(width: 80, alignment: .trailing)
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

    private struct ProblemSegment: Identifiable {
        let id = UUID()
        let fromM: Double
        let toM: Double
        let severity: VoltageDropResult.Severity
        let text: String
        let fix: Fix

        enum Fix {
            case increaseArea
            case decreaseLength
            case changeToCopper
        }

        var color: Color {
            switch severity {
            case .ok: VDColor.ok
            case .warning: VDColor.warning
            case .critical: VDColor.critical
            }
        }

        var icon: String {
            switch severity {
            case .ok: "✅"
            case .warning: "⚠️"
            case .critical: "🛑"
            }
        }
    }

    private func problemSegments(profile: [LinePoint], allowed: Double, voltage: Double, input: VoltageDropInput) -> [ProblemSegment] {
        guard profile.count >= 2 else { return [] }
        let warn = allowed * max(1.0, store.settings.warningMultiplier)
        let crit = allowed * max(warn, store.settings.criticalMultiplier)

        func severity(at dropV: Double) -> VoltageDropResult.Severity {
            let p = (dropV / max(1, voltage)) * 100
            if p <= warn { return .ok }
            if p <= crit { return .warning }
            return .critical
        }

        var segments: [ProblemSegment] = []
        var current: ProblemSegment? = nil

        for (a, b) in zip(profile, profile.dropFirst()) {
            let sev = severity(at: b.dropV)
            guard sev != .ok else {
                if let cur = current {
                    segments.append(cur)
                    current = nil
                }
                continue
            }

            let suggestedFix: ProblemSegment.Fix = {
                if input.material == .aluminum { return .changeToCopper }
                if input.areaMM2 < 10 { return .increaseArea }
                return .decreaseLength
            }()

            let text: String = {
                switch sev {
                case .warning: "ΔU is above the limit — consider strengthening the line."
                case .critical: "ΔU is critical — the load may behave incorrectly."
                case .ok: ""
                }
            }()

            if current == nil {
                current = ProblemSegment(fromM: a.distanceM, toM: b.distanceM, severity: sev, text: text, fix: suggestedFix)
            } else if current?.severity == sev {
                current = ProblemSegment(fromM: current!.fromM, toM: b.distanceM, severity: sev, text: text, fix: suggestedFix)
            } else {
                segments.append(current!)
                current = ProblemSegment(fromM: a.distanceM, toM: b.distanceM, severity: sev, text: text, fix: suggestedFix)
            }
        }

        if let cur = current { segments.append(cur) }
        return segments
    }

    private func applyFix(_ fix: ProblemSegment.Fix) {
        var input = resolvedInput()
        switch fix {
        case .increaseArea:
            input.areaMM2 = nextAreaUp(input.areaMM2)
        case .decreaseLength:
            input.lengthM = max(0, input.lengthM * 0.8)
        case .changeToCopper:
            input.material = .copper
        }

        if source == .calculator {
            store.lastCalculatorInput = input
        }
    }

    private func nextAreaUp(_ a: Double) -> Double {
        let common: [Double] = [1.5, 2.5, 4, 6, 10, 16, 25, 35, 50, 70, 95, 120, 150, 185, 240]
        if let next = common.first(where: { $0 > a }) { return next }
        return a * 1.25
    }
}

#Preview {
    NavigationStack { LineAnalysisView().environmentObject(AppStore()) }
}

