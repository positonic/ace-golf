import GolfCore
import MapKit
import SwiftUI

/// One drawable polygon from the course model.
struct HoleOverlay: Identifiable {
    enum Kind { case fairway, bunker, water, tee, green }
    let id: Int
    let kind: Kind
    let ring: [CLLocationCoordinate2D]

    static func overlays(for hole: Hole) -> [HoleOverlay] {
        var out: [HoleOverlay] = []
        var n = 0
        func add(_ kind: Kind, _ rings: [[Coordinate]]) {
            for r in rings where r.count >= 3 { out.append(HoleOverlay(id: n, kind: kind, ring: r.cl)); n += 1 }
        }
        // Draw order: fairway under everything, green on top.
        add(.fairway, hole.fairways)
        add(.water, hole.water)
        add(.bunker, hole.bunkers)
        add(.tee, hole.tees.map(\.polygon))
        add(.green, [hole.green])
        return out
    }

    var fill: Color {
        switch kind {
        case .fairway: Color(red: 0.55, green: 0.85, blue: 0.35).opacity(0.25)
        case .bunker: Color(red: 0.98, green: 0.90, blue: 0.65).opacity(0.75)
        case .water: Color(red: 0.35, green: 0.65, blue: 0.95).opacity(0.55)
        case .tee: Color(red: 0.20, green: 0.60, blue: 0.30).opacity(0.65)
        case .green: Color(red: 0.25, green: 0.90, blue: 0.65).opacity(0.55)
        }
    }

    var stroke: Color {
        switch kind {
        case .fairway: .white.opacity(0.35)
        case .bunker: Color(red: 0.85, green: 0.70, blue: 0.35)
        case .water: .blue
        case .tee: .white.opacity(0.8)
        case .green: .white
        }
    }

    var lineWidth: CGFloat { kind == .green ? 2 : 1 }
}
