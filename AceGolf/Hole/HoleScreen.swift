import GolfCore
import SwiftUI

/// The on-course screen: header with hole number and par, prev/next, and the hole map.
struct HoleScreen: View {
    let course: Course
    @State private var holeNumber: Int

    init(course: Course, initialHole: Int) {
        self.course = course
        _holeNumber = State(initialValue: initialHole)
    }

    private var hole: Hole? { course.hole(number: holeNumber) }
    private var numbers: [Int] { course.holes.map(\.number) }

    var body: some View {
        ZStack(alignment: .top) {
            if let hole {
                HoleMapView(hole: hole).ignoresSafeArea()
            } else {
                ContentUnavailableView("No hole \(holeNumber)", systemImage: "flag.slash")
            }
            header
        }
    }

    private var header: some View {
        HStack {
            Button(action: previous) { Image(systemName: "chevron.left") }
                .frame(width: 56, height: 56)
                .accessibilityLabel("Previous hole")
            Spacer()
            VStack(spacing: 2) {
                Text("Hole \(holeNumber)").font(.title2.weight(.bold))
                if let par = hole?.par {
                    Text("Par \(par)").font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button(action: next) { Image(systemName: "chevron.right") }
                .frame(width: 56, height: 56)
                .accessibilityLabel("Next hole")
        }
        .font(.title2.weight(.semibold))
        .padding(.horizontal, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 12)
        .padding(.top, 4)
    }

    private func previous() { step(-1) }
    private func next() { step(1) }

    private func step(_ delta: Int) {
        guard let i = numbers.firstIndex(of: holeNumber), !numbers.isEmpty else { return }
        holeNumber = numbers[(i + delta + numbers.count) % numbers.count]
    }
}
