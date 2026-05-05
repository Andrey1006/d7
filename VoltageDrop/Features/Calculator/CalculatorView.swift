import Charts
import SwiftUI

struct CalculatorView: View {
    @EnvironmentObject private var store: AppStore
    @StateObject private var model = CalculatorViewModel()

    @State private var lengthText: String = ""
    @State private var areaText: String = ""
    @State private var voltageText: String = ""
    @State private var currentText: String = ""
    @State private var powerText: String = ""
    @State private var pfText: String = ""
    @State private var allowedText: String = ""

    @State private var showSaveSheet = false
    @State private var saveName = ""
    @State private var saveToProjectId: UUID? = nil
    @State private var voltagePreset: Double? = nil

    var body: some View {
        VDScreen("⚡ Calculator") {
            VDCard("Key metrics") {
                let tone = metricTone(for: model.result.severity)
                let recommended = AreaRecommendation.minimalAreaMeetingLimit(input: model.input, settings: store.settings)
                LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
                    VDMetric(
                        icon: "📉",
                        title: "ΔU",
                        value: formatV(model.result.dropV) + " • " + formatPercent(model.result.dropPercent),
                        subtitle: severityText(model.result.severity),
                        tone: tone
                    )
                    VDMetric(
                        icon: "⚡",
                        title: "Load voltage",
                        value: formatV(model.result.loadVoltageV),
                        subtitle: nil,
                        tone: .neutral
                    )
                    VDMetric(
                        icon: "⚠️",
                        title: "ΔU limit",
                        value: formatPercent(model.input.allowedDropPercent),
                        subtitle: nil,
                        tone: .neutral
                    )
                    VDMetric(
                        icon: "📏",
                        title: "Loss",
                        value: formatW(model.result.lossW),
                        subtitle: nil,
                        tone: .neutral
                    )
                }

                if let recommended {
                    Text("Recommended area: **\(formatRaw(recommended)) mm²** (for limit \(formatPercent(model.input.allowedDropPercent))).")
                        .font(VDTypography.caption)
                        .foregroundStyle(VDColor.secondary)
                } else {
                    Text("Recommended area: no solution in the standard set.")
                        .font(VDTypography.caption)
                        .foregroundStyle(VDColor.secondary)
                }
            }

            VDCard("Line profile") {
                Chart {
                    ForEach(lineSegments(), id: \.id) { seg in
                        LineMark(
                            x: .value("m", seg.a.distanceM),
                            y: .value("ΔU, V", seg.a.dropV)
                        )
                        LineMark(
                            x: .value("m", seg.b.distanceM),
                            y: .value("ΔU, V", seg.b.dropV)
                        )
                        .foregroundStyle(seg.color)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(.init(lineWidth: 2))
                    }

                    if let p = model.selectedPoint {
                        RuleMark(x: .value("m", p.distanceM))
                            .foregroundStyle(VDColor.title.opacity(0.35))
                        PointMark(
                            x: .value("m", p.distanceM),
                            y: .value("ΔU, V", p.dropV)
                        )
                        .symbolSize(55)
                        .foregroundStyle(VDColor.title)
                    }
                }
                .chartYScale(domain: 0...max(1, (model.profile.last?.dropV ?? 1) * 1.15))
                .frame(height: 180)
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
                                            model.selectDistance(d)
                                        }
                                    }
                            )
                    }
                }

                if let p = model.selectedPoint {
                    Text("📍 \(formatM(p.distanceM)) m • ΔU \(formatV(p.dropV)) • U \(formatV(p.voltageV))")
                        .font(VDTypography.caption)
                        .foregroundStyle(VDColor.secondary)
                } else {
                    Text("Drag on the chart to select a point and highlight it in the table.")
                        .font(VDTypography.caption)
                        .foregroundStyle(VDColor.secondary)
                }
            }

            VDCard("Inputs") {
                VStack(alignment: .leading, spacing: 12) {
                    Picker("Voltage preset", selection: $voltagePreset) {
                        Text("Custom").tag(Double?.none)
                        ForEach(store.settings.voltagePresets, id: \.self) { v in
                            Text("\(formatRaw(v)) V").tag(Optional(v))
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: voltagePreset) { newValue in
                        guard let v = newValue else { return }
                        voltageText = formatRaw(v)
                    }

                    HStack(spacing: 12) {
                        VDField(
                            title: "Voltage",
                            placeholder: "230",
                            text: $voltageText,
                            keyboard: .decimalPad,
                            trailing: "V",
                            isInvalid: !(VDNumber.parse(voltageText).map { $0 > 0 } ?? true)
                        )
                        VDField(
                            title: "cosφ",
                            placeholder: "0.95",
                            text: $pfText,
                            keyboard: .decimalPad,
                            trailing: "",
                            isInvalid: !(VDNumber.parse(pfText).map { $0 > 0 && $0 <= 1 } ?? true)
                        )
                    }

                    HStack(spacing: 12) {
                        VDField(
                            title: "Length",
                            placeholder: "30",
                            text: $lengthText,
                            keyboard: .decimalPad,
                            trailing: "m",
                            isInvalid: !(VDNumber.parse(lengthText).map { $0 >= 0 } ?? true)
                        )
                        VDField(
                            title: "Area",
                            placeholder: "2.5",
                            text: $areaText,
                            keyboard: .decimalPad,
                            trailing: "mm²",
                            isInvalid: !(VDNumber.parse(areaText).map { $0 > 0 } ?? true)
                        )
                    }

                    HStack(spacing: 12) {
                        Picker("Phase", selection: phaseBinding) {
                            ForEach(PhaseSystem.allCases) { phase in
                                Text(phase.rawValue).tag(phase)
                            }
                        }
                        .pickerStyle(.segmented)

                        Picker("Material", selection: materialBinding) {
                            ForEach(ConductorMaterial.allCases) { m in
                                Text(m.rawValue).tag(m)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Picker("Load", selection: modeBinding) {
                        ForEach(LoadInputMode.allCases) { mode in
                            Text(mode == .current ? "I" : "P").tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    if model.input.loadMode == .current {
                        VDField(
                            title: "Current",
                            placeholder: "16",
                            text: $currentText,
                            keyboard: .decimalPad,
                            trailing: "A",
                            isInvalid: !(VDNumber.parse(currentText).map { $0 >= 0 } ?? true)
                        )
                    } else {
                        VDField(
                            title: "Power",
                            placeholder: "2000",
                            text: $powerText,
                            keyboard: .decimalPad,
                            trailing: "W",
                            isInvalid: !(VDNumber.parse(powerText).map { $0 >= 0 } ?? true)
                        )
                    }

                    VDField(
                        title: "Allowed drop",
                        placeholder: "3",
                        text: $allowedText,
                        keyboard: .decimalPad,
                        trailing: "%",
                        isInvalid: !(VDNumber.parse(allowedText).map { $0 > 0 } ?? true)
                    )

                    HStack(spacing: 12) {
                        VDPrimaryButton("Save", icon: "square.and.arrow.down") {
                            showSave()
                        }
                        VDPrimaryButton("Apply", icon: "checkmark") {
                            applyEditsAndRecalc()
                        }
                    }
                }
            }

            VDCard("Table") {
                VStack(spacing: 8) {
                    headerRow()
                    ForEach(model.profile) { p in
                        row(p)
                            .padding(.horizontal, 8)
                            .background(rowBackground(for: p))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .onTapGesture { model.selectDistance(p.distanceM) }
                    }
                }
            }
        }
        .onAppear {
            model.updateSettings(store.settings)
            seedTextsIfNeeded()
            applyEditsAndRecalc()
        }
        .onChange(of: store.settings) { newValue in
            model.updateSettings(newValue)
        }
        .onChange(of: voltageText) { _ in applyEditsAndRecalc() }
        .onChange(of: pfText) { _ in applyEditsAndRecalc() }
        .onChange(of: lengthText) { _ in applyEditsAndRecalc() }
        .onChange(of: areaText) { _ in applyEditsAndRecalc() }
        .onChange(of: currentText) { _ in if model.input.loadMode == .current { applyEditsAndRecalc() } }
        .onChange(of: powerText) { _ in if model.input.loadMode == .power { applyEditsAndRecalc() } }
        .onChange(of: allowedText) { _ in applyEditsAndRecalc() }
        .sheet(isPresented: $showSaveSheet) {
            saveSheet()
        }
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
            Text(formatV(p.dropV)).frame(width: 80, alignment: .trailing)
            Text(formatV(p.voltageV)).frame(width: 80, alignment: .trailing)
            Text(formatW(p.lossW)).frame(width: 80, alignment: .trailing)
        }
        .vdFullWidthCell()
        .font(VDTypography.body.monospaced())
        .foregroundStyle(VDColor.title)
        .padding(.vertical, 4)
    }

    private var phaseBinding: Binding<PhaseSystem> {
        Binding(
            get: { model.input.phase },
            set: { model.input.phase = $0; model.recalc(); seedTextsIfNeeded() }
        )
    }

    private var materialBinding: Binding<ConductorMaterial> {
        Binding(
            get: { model.input.material },
            set: { model.input.material = $0; model.recalc() }
        )
    }

    private var modeBinding: Binding<LoadInputMode> {
        Binding(
            get: { model.input.loadMode },
            set: { model.input.loadMode = $0; model.recalc() }
        )
    }

    private func applyEditsAndRecalc() {
        if let v = VDNumber.parse(voltageText) { model.input.systemVoltage = v }
        if let pf = VDNumber.parse(pfText) { model.input.powerFactor = pf }
        if let l = VDNumber.parse(lengthText) { model.input.lengthM = l }
        if let a = VDNumber.parse(areaText) { model.input.areaMM2 = a }
        if let ad = VDNumber.parse(allowedText) { model.input.allowedDropPercent = ad }

        if model.input.loadMode == .current {
            if let i = VDNumber.parse(currentText) { model.input.currentA = i }
        } else {
            if let p = VDNumber.parse(powerText) { model.input.powerW = p }
        }

        model.recalc()
        store.lastCalculatorInput = model.input
    }

    private func seedTextsIfNeeded() {
        if voltageText.isEmpty { voltageText = formatRaw(model.input.systemVoltage) }
        if pfText.isEmpty { pfText = formatRaw(model.input.powerFactor) }
        if lengthText.isEmpty { lengthText = formatRaw(model.input.lengthM) }
        if areaText.isEmpty { areaText = formatRaw(model.input.areaMM2) }
        if currentText.isEmpty { currentText = formatRaw(model.input.currentA) }
        if powerText.isEmpty { powerText = formatRaw(model.input.powerW) }
        if allowedText.isEmpty || model.input.allowedDropPercent <= 0 {
            model.input.allowedDropPercent = store.settings.allowedDropPercentDefault
            allowedText = formatRaw(model.input.allowedDropPercent)
        }
    }

    private func metricTone(for severity: VoltageDropResult.Severity) -> VDMetric.VDTone {
        switch severity {
        case .ok: .ok
        case .warning: .warning
        case .critical: .critical
        }
    }

    private func severityText(_ s: VoltageDropResult.Severity) -> String {
        switch s {
        case .ok: "✅ OK"
        case .warning: "⚠️ Above limit"
        case .critical: "🛑 Critical"
        }
    }

    private func formatV(_ v: Double) -> String { "\(formatRaw(v)) V" }
    private func formatW(_ w: Double) -> String { "\(formatRaw(w)) W" }
    private func formatM(_ m: Double) -> String { "\(formatRaw(m))" }
    private func formatPercent(_ p: Double) -> String { "\(formatRaw(p))%" }

    private func formatRaw(_ value: Double) -> String {
        let f = NumberFormatter()
        f.locale = .current
        f.numberStyle = .decimal
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }

    private func showSave() {
        seedTextsIfNeeded()
        saveName = "Line \(DateFormatter.short.string(from: Date()))"
        saveToProjectId = store.projects.first?.id
        showSaveSheet = true
    }

    private func saveSheet() -> some View {
        NavigationStack {
            VDScreen("Save") {
                VDCard("Name") {
                    VDField(title: "Title", placeholder: "Line", text: $saveName, keyboard: .default, trailing: nil)
                }

                VDCard("Save to") {
                    VStack(alignment: .leading, spacing: 10) {
                        Picker("Project", selection: Binding(get: { saveToProjectId }, set: { saveToProjectId = $0 })) {
                            Text("Variants (no project)").tag(UUID?.none)
                            ForEach(store.projects) { p in
                                Text(p.title).tag(Optional(p.id))
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                VDPrimaryButton("Save", icon: "checkmark") {
                    if let pid = saveToProjectId {
                        store.addLine(to: pid, name: saveName.nonEmptyOr("Line"), input: model.input)
                    } else {
                        store.upsertVariant(name: saveName.nonEmptyOr("Variant"), input: model.input)
                    }
                    showSaveSheet = false
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { showSaveSheet = false }
                }
            }
        }
    }

    private func rowBackground(for p: LinePoint) -> Color {
        guard let selected = model.selectedPoint else { return Color.clear }
        if abs(selected.distanceM - p.distanceM) < 0.0001 {
            return VDColor.accent.opacity(0.10)
        }
        return Color.clear
    }

    private struct Segment: Identifiable {
        let id = UUID()
        let a: LinePoint
        let b: LinePoint
        let color: Color
    }

    private func lineSegments() -> [Segment] {
        let pts = model.profile
        guard pts.count >= 2 else { return [] }

        let allowed = max(0.1, model.input.allowedDropPercent)
        let warn = allowed * max(1.0, store.settings.warningMultiplier)
        let crit = allowed * max(warn, store.settings.criticalMultiplier)

        func toneColor(dropV: Double) -> Color {
            let p = (dropV / max(1, model.input.systemVoltage)) * 100.0
            if p <= warn { return VDColor.ok }
            if p <= crit { return VDColor.warning }
            return VDColor.critical
        }

        return zip(pts, pts.dropFirst()).map { a, b in
            Segment(a: a, b: b, color: toneColor(dropV: b.dropV))
        }
    }
}

#Preview {
    NavigationStack { CalculatorView().environmentObject(AppStore()) }
}

