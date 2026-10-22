import GolfCore
import SwiftUI

/// Front / middle / back to the green, in whole metres, large enough to read in sunlight.
struct DistancePanel: View {
    let distances: GreenDistances?
    let fix: LocationFix?
    let isDenied: Bool

    private var isDim: Bool { fix.map { !$0.isPrecise } ?? true }

    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                column("FRONT", distances?.front, size: 40)
                column("MIDDLE", distances?.middle, size: 56)
                column("BACK", distances?.back, size: 40)
            }
            status
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    private func column(_ label: String, _ value: Double?, size: CGFloat) -> some View {
        VStack(spacing: 0) {
            Text(value.map { String(Int($0.rounded())) } ?? "—")
                .font(.system(size: size, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(isDim ? .secondary : .primary)
                .contentTransition(.numericText())
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private var status: some View {
        if isDenied {
            Text("Location access denied. Enable it in Settings.")
                .font(.footnote.weight(.semibold)).foregroundStyle(.red)
        } else if let fix {
            if !fix.isPrecise {
                Text("GPS ±\(Int(fix.acc.rounded())) m")
                    .font(.footnote.weight(.semibold)).foregroundStyle(.orange)
            }
        } else {
            Text("Waiting for GPS…")
                .font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
        }
    }
}
