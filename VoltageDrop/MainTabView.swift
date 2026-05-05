import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack { CalculatorView() }
                .tabItem { Label("Calculator", systemImage: "bolt.fill") }

            NavigationStack { LineAnalysisView() }
                .tabItem { Label("Line", systemImage: "chart.xyaxis.line") }

            NavigationStack { VariantsView() }
                .tabItem { Label("Variants", systemImage: "ruler") }

            NavigationStack { ProjectsView() }
                .tabItem { Label("Projects", systemImage: "folder") }

            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}

#Preview {
    MainTabView()
}

