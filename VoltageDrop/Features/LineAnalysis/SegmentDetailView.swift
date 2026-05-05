import SwiftUI

struct SegmentDetailView: View {
    @EnvironmentObject private var store: AppStore

    @State var input: VoltageDropInput
    let fromM: Double
    let toM: Double

    var body: some View {
        let evaluated = VoltageDropCalculator.evaluate(input: input, settings: store.settings)
        let end = evaluated.profile.last
        return VDScreen("⚠️ Segment") {
            VDCard("Range") {
                Text("\(VDNumber.format(fromM, fractionDigits: 0))–\(VDNumber.format(toM, fractionDigits: 0)) m")
                    .font(VDTypography.headline)
                    .foregroundStyle(VDColor.title)
                if let end {
                    Text("End drop: \(VDNumber.format(end.dropV)) V • U: \(VDNumber.format(end.voltageV)) V")
                        .font(VDTypography.caption)
                        .foregroundStyle(VDColor.secondary)
                }
            }

            VDCard("Quick fixes") {
                VStack(spacing: 10) {
                    VDPrimaryButton("Increase area", icon: "arrow.up.right") {
                        input.areaMM2 = nextAreaUp(input.areaMM2)
                    }
                    VDPrimaryButton("Reduce length by 20%", icon: "scissors") {
                        input.lengthM = max(0, input.lengthM * 0.8)
                    }
                    if input.material == .aluminum {
                        VDPrimaryButton("Switch to Cu", icon: "arrow.triangle.2.circlepath") {
                            input.material = .copper
                        }
                    }
                }
            }

            VDCard("Apply") {
                VDPrimaryButton("Set as active (⚡)", icon: "bolt.fill") {
                    store.lastCalculatorInput = input
                }
            }
        }
        .vdHidesTabBarOnPush()
    }

    private func nextAreaUp(_ a: Double) -> Double {
        let common = AreaRecommendation.commonAreas
        if let next = common.first(where: { $0 > a }) { return next }
        return a * 1.25
    }
}

#Preview {
    NavigationStack {
        SegmentDetailView(input: .init(systemVoltage: 230, phase: .singlePhase, loadMode: .current, currentA: 16, powerW: 0, powerFactor: 0.95, lengthM: 60, areaMM2: 1.5, material: .aluminum, allowedDropPercent: 3), fromM: 20, toM: 60)
            .environmentObject(AppStore())
    }
}

