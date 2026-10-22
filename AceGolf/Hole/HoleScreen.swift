import GolfCore
import SwiftUI

/// The on-course screen: header with hole number and par, prev/next, and the hole map.
struct HoleScreen: View {
    let course: Course
    @State private var holeNumber: Int
    @State private var location = LocationService()
    @State private var measurePoint: Coordinate?
    @State private var showAbout = false
    @Environment(\.scenePhase) private var scenePhase

    init(course: Course, initialHole: Int) {
        self.course = course
        _holeNumber = State(initialValue: initialHole)
    }

    private var hole: Hole? { course.hole(number: holeNumber) }
    private var numbers: [Int] { course.holes.map(\.number) }

    private var distances: GreenDistances? {
        guard let hole, let fix = location.latest else { return nil }
        return GreenDistances.from(fix.coordinate, to: hole.green)
    }

    var body: some View {
        ZStack {
            if let hole {
                HoleMapView(hole: hole, fix: location.latest, measurePoint: $measurePoint).ignoresSafeArea()
            } else {
                ContentUnavailableView("No hole \(holeNumber)", systemImage: "flag.slash")
            }
            VStack {
                header
                measureChip
                Spacer()
                DistancePanel(distances: distances, fix: location.latest, isDenied: location.isDenied)
            }
        }
        .task { location.start() }
        .onChange(of: holeNumber) { measurePoint = nil }
        .sheet(isPresented: $showAbout) { AboutView() }
        .onChange(of: scenePhase) { _, phase in
            // Foreground only by design: no background location, no battery drain in the pocket.
            if phase == .active { location.start() } else if phase == .background { location.stop() }
        }
    }

    private var header: some View {
        HStack {
            Button(action: previous) { Image(systemName: "chevron.left") }
                .frame(width: 56, height: 56)
                .accessibilityLabel("Previous hole")
            Spacer()
            Button { showAbout = true } label: {
                VStack(spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Hole \(holeNumber)").font(.title2.weight(.bold))
                        Image(systemName: "info.circle").font(.footnote).foregroundStyle(.secondary)
                    }
                    if let par = hole?.par {
                        Text("Par \(par)").font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("About Ace Golf")
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

    /// Distance from the current fix to the tapped pin.
    private var measureDistance: Double? {
        guard let measurePoint, let fix = location.latest else { return nil }
        return Geometry.distance(fix.coordinate, measurePoint)
    }

    @ViewBuilder private var measureChip: some View {
        if measurePoint != nil {
            HStack(spacing: 10) {
                Image(systemName: "mappin").foregroundStyle(.yellow)
                Text(measureDistance.map { "\(Int($0.rounded())) m" } ?? "No GPS fix")
                    .font(.title3.weight(.bold)).monospacedDigit()
                Button { measurePoint = nil } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .accessibilityLabel("Clear measurement")
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
            .padding(.top, 6)
        }
    }

    private func previous() { step(-1) }
    private func next() { step(1) }

    private func step(_ delta: Int) {
        guard let i = numbers.firstIndex(of: holeNumber), !numbers.isEmpty else { return }
        holeNumber = numbers[(i + delta + numbers.count) % numbers.count]
    }
}
