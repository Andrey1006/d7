import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: AppStore
    @State private var page = 0

    var body: some View {
        ZStack {
            VDColor.background.ignoresSafeArea()

            VStack(spacing: 16) {
                header()

                TabView(selection: $page) {
                    step(
                        title: "Engineering calculator ⚡",
                        subtitle: "Enter length, area, conductor material, and load to get ΔU, load voltage, and losses in real time.",
                        bullets: [
                            "Auto-recalculation on every change",
                            "Recommended minimum conductor area",
                            "Save to variants or projects"
                        ],
                        accent: VDColor.accent
                    )
                    .tag(0)

                    step(
                        title: "Line profile & weak spots 📉",
                        subtitle: "Inspect the line profile and locate segments where the system drops.",
                        bullets: [
                            "Chart + table with synced point selection",
                            "Color coding: OK / WARN / CRIT",
                            "Fast fixes to improve parameters"
                        ],
                        accent: VDColor.warning
                    )
                    .tag(1)

                    step(
                        title: "Variants & reports 🗂️",
                        subtitle: "Compare solutions and export a project report.",
                        bullets: [
                            "Compare 2–4 variants by ΔU",
                            "Projects: lines and statuses",
                            "Export PDF and share"
                        ],
                        accent: VDColor.ok
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                footer()
            }
            .padding(16)
        }
    }

    private func header() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Zeuss: Voltage Drop")
                .font(VDTypography.title(26))
                .foregroundStyle(VDColor.title)
            Text("Voltage drop under control.")
                .font(VDTypography.body)
                .foregroundStyle(VDColor.secondary)
        }
        .vdFullWidthCell()
    }

    private func step(title: String, subtitle: String, bullets: [String], accent: Color) -> some View {
        VStack(spacing: 14) {
            VDCard(nil) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(title)
                        .font(VDTypography.title(20))
                        .foregroundStyle(VDColor.title)

                    Text(subtitle)
                        .font(VDTypography.body)
                        .foregroundStyle(VDColor.secondary)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(bullets, id: \.self) { b in
                            HStack(alignment: .top, spacing: 8) {
                                Circle()
                                    .fill(accent)
                                    .frame(width: 6, height: 6)
                                    .padding(.top, 6)
                                Text(b)
                                    .font(VDTypography.body)
                                    .foregroundStyle(VDColor.title)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(.top, 4)
        .padding(.bottom, 8)
    }

    private func footer() -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Button("Skip") {
                    finish()
                }
                .buttonStyle(.plain)
                .font(VDTypography.caption)
                .foregroundStyle(VDColor.secondary)
                .vdFullWidthCell(alignment: .leading)

                VDPrimaryButton(page == 2 ? "Get started" : "Next", icon: "chevron.right") {
                    if page < 2 {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            page += 1
                        }
                    } else {
                        finish()
                    }
                }
            }
        }
    }

    private func finish() {
        store.hasSeenOnboarding = true
    }
}

#Preview {
    OnboardingView().environmentObject(AppStore())
}

