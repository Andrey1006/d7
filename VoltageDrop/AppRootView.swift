import SwiftUI

struct AppRootView: View {
    @StateObject private var store = AppStore()

    var body: some View {
        MainTabView()
            .environmentObject(store)
            .fullScreenCover(isPresented: Binding(
                get: { store.hasSeenOnboarding == false },
                set: { _ in }
            )) {
                OnboardingView()
                    .environmentObject(store)
            }
    }
}

#Preview {
    AppRootView()
}

