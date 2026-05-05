import Combine
import Foundation

@MainActor
final class AppStore: ObservableObject {
    @Published var settings: VDSettings {
        didSet { persist() }
    }

    @Published var variants: [VDVariant] {
        didSet { persist() }
    }

    @Published var projects: [VDProject] {
        didSet { persist() }
    }

    @Published var lastCalculatorInput: VoltageDropInput {
        didSet { persist() }
    }

    @Published var hasSeenOnboarding: Bool {
        didSet { persist() }
    }

    private let store: UserDefaultsJSONStore

    private enum Keys {
        static let settings = "vd.settings"
        static let variants = "vd.variants"
        static let projects = "vd.projects"
        static let lastCalculatorInput = "vd.lastCalculatorInput"
        static let hasSeenOnboarding = "vd.hasSeenOnboarding"
    }

    init(store: UserDefaultsJSONStore? = nil) {
        let s = store ?? UserDefaultsJSONStore()
        self.store = s
        self.settings = s.load(VDSettings.self, key: Keys.settings) ?? .default
        self.variants = s.load([VDVariant].self, key: Keys.variants) ?? []
        self.projects = s.load([VDProject].self, key: Keys.projects) ?? []
        self.lastCalculatorInput = s.load(VoltageDropInput.self, key: Keys.lastCalculatorInput) ?? VoltageDropInput(
            systemVoltage: 230,
            phase: .singlePhase,
            loadMode: .current,
            currentA: 16,
            powerW: 2000,
            powerFactor: 0.95,
            lengthM: 30,
            areaMM2: 2.5,
            material: .copper,
            allowedDropPercent: (s.load(VDSettings.self, key: Keys.settings) ?? .default).allowedDropPercentDefault
        )
        self.hasSeenOnboarding = s.loadBool(key: Keys.hasSeenOnboarding) ?? false
    }

    func upsertVariant(name: String, input: VoltageDropInput) {
        let v = VDVariant(id: UUID(), createdAt: Date(), name: name, input: input)
        variants.insert(v, at: 0)
    }

    func createProject(title: String, notes: String = "") -> VDProject {
        let p = VDProject(id: UUID(), createdAt: Date(), title: title, notes: notes, lines: [])
        projects.insert(p, at: 0)
        return p
    }

    func addLine(to projectId: UUID, name: String, input: VoltageDropInput) {
        guard let idx = projects.firstIndex(where: { $0.id == projectId }) else { return }
        let line = VDLine(id: UUID(), createdAt: Date(), name: name, input: input)
        projects[idx].lines.insert(line, at: 0)
    }

    func renameProject(_ id: UUID, title: String, notes: String) {
        guard let idx = projects.firstIndex(where: { $0.id == id }) else { return }
        projects[idx].title = title
        projects[idx].notes = notes
    }

    func renameLine(projectId: UUID, lineId: UUID, name: String) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectId }) else { return }
        guard let lIdx = projects[pIdx].lines.firstIndex(where: { $0.id == lineId }) else { return }
        projects[pIdx].lines[lIdx].name = name
    }

    func deleteLine(projectId: UUID, lineId: UUID) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectId }) else { return }
        projects[pIdx].lines.removeAll { $0.id == lineId }
    }

    func deleteProject(_ id: UUID) {
        projects.removeAll { $0.id == id }
    }

    func deleteVariant(_ id: UUID) {
        variants.removeAll { $0.id == id }
    }

    private func persist() {
        store.save(settings, key: Keys.settings)
        store.save(variants, key: Keys.variants)
        store.save(projects, key: Keys.projects)
        store.save(lastCalculatorInput, key: Keys.lastCalculatorInput)
        store.saveBool(hasSeenOnboarding, key: Keys.hasSeenOnboarding)
    }
}

