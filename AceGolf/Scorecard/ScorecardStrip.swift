import GolfCore
import SwiftUI

/// Compact 18-hole strip: tap a hole to load it, +/- adjusts the selected hole, total and to-par at the end.
struct ScorecardStrip: View {
    let course: Course
    let store: RoundStore
    @Binding var selectedHole: Int

    var body: some View {
        HStack(spacing: 8) {
            stepper
            ScrollViewReader { reader in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(course.holes, id: \.number) { hole in
                            cell(hole).id(hole.number)
                        }
                        totals.padding(.leading, 6)
                    }
                    .padding(.horizontal, 4)
                }
                .onChange(of: selectedHole, initial: true) { _, n in
                    withAnimation { reader.scrollTo(n, anchor: .center) }
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 12)
    }

    private var stepper: some View {
        HStack(spacing: 0) {
            Button { store.adjustStrokes(hole: selectedHole, by: -1) } label: {
                Image(systemName: "minus").frame(width: 36, height: 44)
            }
            .accessibilityLabel("One stroke fewer")
            Text(store.round.strokes(hole: selectedHole).map(String.init) ?? "–")
                .font(.title2.weight(.heavy)).monospacedDigit()
                .frame(minWidth: 28)
            Button { store.adjustStrokes(hole: selectedHole, by: 1) } label: {
                Image(systemName: "plus").frame(width: 36, height: 44)
            }
            .accessibilityLabel("One stroke more")
        }
        .font(.title3.weight(.bold))
    }

    private func cell(_ hole: Hole) -> some View {
        let strokes = store.round.strokes(hole: hole.number)
        let selected = hole.number == selectedHole
        return Button { selectedHole = hole.number } label: {
            VStack(spacing: 1) {
                Text("\(hole.number)").font(.caption2.weight(.bold))
                    .foregroundStyle(selected ? Color.white : .secondary)
                Text(strokes.map(String.init) ?? "·")
                    .font(.callout.weight(.heavy)).monospacedDigit()
                    .foregroundStyle(scoreColor(strokes: strokes, par: hole.par, selected: selected))
                Text(hole.par.map { "\($0)" } ?? "")
                    .font(.caption2).foregroundStyle(selected ? Color.white.opacity(0.8) : .secondary)
            }
            .frame(width: 30, height: 48)
            .background(selected ? Color.accentColor : Color.clear, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Hole \(hole.number)")
    }

    private func scoreColor(strokes: Int?, par: Int?, selected: Bool) -> Color {
        guard let strokes, let par else { return selected ? .white : .primary }
        if selected { return .white }
        switch strokes - par {
        case ..<0: return .green
        case 0: return .primary
        default: return .red
        }
    }

    private var totals: some View {
        VStack(spacing: 1) {
            Text("\(store.totalStrokes)").font(.callout.weight(.heavy)).monospacedDigit()
            Text(store.toPar.map(formatToPar) ?? "")
                .font(.caption.weight(.bold)).foregroundStyle(.secondary).monospacedDigit()
        }
        .frame(minWidth: 40)
    }
}
