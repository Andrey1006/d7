import Foundation
import UIKit

enum PDFReportRenderer {
    static func renderProject(_ project: VDProject, settings: VDSettings) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        return renderer.pdfData { ctx in
            ctx.beginPage()
            var y: CGFloat = 28

            func draw(_ text: String, font: UIFont, color: UIColor = .black) {
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: color
                ]
                let s = NSAttributedString(string: text, attributes: attrs)
                s.draw(at: CGPoint(x: 28, y: y))
                y += font.lineHeight + 8
            }

            draw("Zeuss: Voltage Drop — Project Report", font: .systemFont(ofSize: 18, weight: .semibold))
            draw(project.title, font: .systemFont(ofSize: 14, weight: .medium))
            if !project.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                draw(project.notes, font: .systemFont(ofSize: 12, weight: .regular), color: .darkGray)
            }

            y += 6
            draw("Lines: \(project.lines.count)", font: .systemFont(ofSize: 12, weight: .regular), color: .darkGray)
            draw("Allowed ΔU default: \(format(settings.allowedDropPercentDefault))% • Steps: \(settings.profileSteps)", font: .systemFont(ofSize: 10, weight: .regular), color: .gray)
            draw("Temp: \(format(settings.conductorTemperatureC))°C • X: \(settings.useReactance ? format(settings.reactanceOhmPerKm) + " Ω/km" : "off")", font: .systemFont(ofSize: 10, weight: .regular), color: .gray)
            y += 10

            for line in project.lines {
                if y > pageRect.height - 120 {
                    ctx.beginPage()
                    y = 28
                }

                let res = VoltageDropCalculator.evaluate(input: line.input, settings: settings).result
                draw("• \(line.name)  [\(severity(res.severity))]", font: .systemFont(ofSize: 12, weight: .semibold))
                draw("ΔU: \(format(res.dropV)) V (\(format(res.dropPercent))%)", font: .systemFont(ofSize: 11, weight: .regular))
                draw("U_load: \(format(res.loadVoltageV)) V • Loss: \(format(res.lossW)) W", font: .systemFont(ofSize: 11, weight: .regular), color: .darkGray)
                draw("L: \(format(line.input.lengthM)) m • A: \(format(line.input.areaMM2)) mm² • \(line.input.material.rawValue) • \(line.input.phase.rawValue)", font: .systemFont(ofSize: 10, weight: .regular), color: .gray)
                draw("Limit: \(format(line.input.allowedDropPercent))% • cosφ: \(format(line.input.powerFactor))", font: .systemFont(ofSize: 10, weight: .regular), color: .gray)
                y += 6
            }
        }
    }

    private static func format(_ v: Double) -> String {
        let f = NumberFormatter()
        f.locale = .current
        f.numberStyle = .decimal
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 0
        return f.string(from: NSNumber(value: v)) ?? "\(v)"
    }

    private static func severity(_ s: VoltageDropResult.Severity) -> String {
        switch s {
        case .ok: "OK"
        case .warning: "WARN"
        case .critical: "CRIT"
        }
    }
}

