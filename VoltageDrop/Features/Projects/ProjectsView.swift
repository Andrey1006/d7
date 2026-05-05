import SwiftUI

struct ProjectsView: View {
    @EnvironmentObject private var store: AppStore

    @State private var showNewProject = false
    @State private var newTitle = ""
    @State private var newNotes = ""

    @State private var shareData: Data? = nil

    var body: some View {
        VDScreen("🗂️ Projects") {
            VDCard("Projects") {
                if store.projects.isEmpty {
                    Text("No projects yet. Create one and save lines from the calculator.")
                        .font(VDTypography.caption)
                        .foregroundStyle(VDColor.secondary)
                } else {
                    VStack(spacing: 8) {
                        ForEach(store.projects) { p in
                            NavigationLink {
                                ProjectDetailView(projectId: p.id)
                                    .environmentObject(store)
                            } label: {
                                projectRow(p)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            VDPrimaryButton("New project", icon: "folder.badge.plus") {
                newTitle = ""
                newNotes = ""
                showNewProject = true
            }
        }
        .sheet(isPresented: $showNewProject) {
            newProjectSheet()
        }
        .sheet(item: Binding(get: {
            shareData.map { SharePayload(data: $0) }
        }, set: { payload in
            shareData = payload?.data
        })) { payload in
            ShareSheet(activityItems: [payload.data])
        }
    }

    private func projectRow(_ p: VDProject) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(p.title)
                    .font(VDTypography.headline)
                    .foregroundStyle(VDColor.title)
                Text("\(p.lines.count) lines")
                    .font(VDTypography.caption)
                    .foregroundStyle(VDColor.secondary)
            }
            Spacer(minLength: 0)

            Button {
                shareData = PDFReportRenderer.renderProject(p, settings: store.settings)
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
            .buttonStyle(.plain)
            .foregroundStyle(VDColor.accent)

            Button(role: .destructive) {
                store.deleteProject(p.id)
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
                .stroke(VDColor.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func newProjectSheet() -> some View {
        NavigationStack {
            VDScreen("New project") {
                VDCard("Details") {
                    VStack(alignment: .leading, spacing: 12) {
                        VDField(title: "Title", placeholder: "Site / project", text: $newTitle, keyboard: .default, trailing: nil, isNumeric: false)
                        VDField(title: "Notes", placeholder: "Optional", text: $newNotes, keyboard: .default, trailing: nil, isNumeric: false)

                        VDPrimaryButton("Create", icon: "checkmark") {
                            let t = newTitle.nonEmptyOr("Project \(DateFormatter.short.string(from: Date()))")
                            _ = store.createProject(title: t, notes: newNotes)
                            showNewProject = false
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { showNewProject = false }
                }
            }
        }
    }

    private struct SharePayload: Identifiable {
        let id = UUID()
        let data: Data
    }
}

#Preview {
    NavigationStack { ProjectsView().environmentObject(AppStore()) }
}

