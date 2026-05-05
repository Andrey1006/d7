import SwiftUI

struct ProjectDetailView: View {
    @EnvironmentObject private var store: AppStore
    let projectId: UUID

    @State private var editing = false
    @State private var title = ""
    @State private var notes = ""

    var body: some View {
        VDScreen("Project") {
            if let p = store.projects.first(where: { $0.id == projectId }) {
                VDCard("Project") {
                    if editing {
                        VStack(alignment: .leading, spacing: 12) {
                            VDField(title: "Title", placeholder: "Project", text: $title, keyboard: .default, trailing: nil, isNumeric: false)
                            VDField(title: "Notes", placeholder: "Optional", text: $notes, keyboard: .default, trailing: nil, isNumeric: false)
                            VDPrimaryButton("Save", icon: "checkmark") {
                                store.renameProject(p.id, title: title.nonEmptyOr(p.title), notes: notes)
                                editing = false
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(p.title)
                                .font(VDTypography.headline)
                                .foregroundStyle(VDColor.title)
                            if !p.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text(p.notes)
                                    .font(VDTypography.caption)
                                    .foregroundStyle(VDColor.secondary)
                            }
                            VDPrimaryButton("Edit", icon: "pencil") {
                                title = p.title
                                notes = p.notes
                                editing = true
                            }
                        }
                    }
                }

                VDCard("Lines") {
                    if p.lines.isEmpty {
                        Text("No lines yet. Save a line to this project from the ⚡ tab.")
                            .font(VDTypography.caption)
                            .foregroundStyle(VDColor.secondary)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(p.lines) { line in
                                NavigationLink {
                                    SavedLineDetailView(projectTitle: p.title, line: line)
                                        .environmentObject(store)
                                } label: {
                                    lineRow(line)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        store.deleteLine(projectId: p.id, lineId: line.id)
                                    } label: {
                                        Text("Delete line")
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                Text("Project not found.")
                    .font(VDTypography.caption)
                    .foregroundStyle(VDColor.secondary)
            }
        }
        .navigationTitle("🗂️ Project")
        .vdHidesTabBarOnPush()
    }

    private func lineRow(_ line: VDLine) -> some View {
        let r = VoltageDropCalculator.evaluate(input: line.input, settings: store.settings).result
        let c: Color = {
            switch r.severity {
            case .ok: VDColor.ok
            case .warning: VDColor.warning
            case .critical: VDColor.critical
            }
        }()

        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(line.name)
                    .font(VDTypography.headline)
                    .foregroundStyle(VDColor.title)
                Text("ΔU \(fmt(r.dropPercent))% • \(line.input.material.rawValue) \(fmt(line.input.areaMM2))mm² • \(fmt(line.input.lengthM))m")
                    .font(VDTypography.caption)
                    .foregroundStyle(VDColor.secondary)
            }
            Spacer(minLength: 0)
            Text(statusEmoji(r.severity))
                .font(VDTypography.caption)
                .foregroundStyle(c)
        }
        .vdFullWidthCell()
        .padding(10)
        .background(VDColor.surfaceMuted)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(c.opacity(0.25), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func statusEmoji(_ s: VoltageDropResult.Severity) -> String {
        switch s {
        case .ok: "✅"
        case .warning: "⚠️"
        case .critical: "🛑"
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
}

#Preview {
    NavigationStack { ProjectDetailView(projectId: UUID()).environmentObject(AppStore()) }
}

