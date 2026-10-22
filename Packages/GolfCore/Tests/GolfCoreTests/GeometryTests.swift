import Foundation
import Testing
@testable import GolfCore

@Suite struct GeometryTests {
    let origin = Coordinate(latitude: 52.78, longitude: 13.57)

    /// Build a coordinate from metres east/north of the origin.
    func at(_ x: Double, _ y: Double) -> Coordinate {
        Geometry.LocalFrame(origin: origin).coordinate(x: x, y: y)
    }

    @Test func distanceMatchesLocalFrame() {
        let d = Geometry.distance(origin, at(300, 400))
        #expect(abs(d - 500) < 0.5)
    }

    @Test func bearingCardinals() {
        #expect(abs(Geometry.bearing(from: origin, to: at(0, 100)) - 0) < 0.01)
        #expect(abs(Geometry.bearing(from: origin, to: at(100, 0)) - 90) < 0.01)
        #expect(abs(Geometry.bearing(from: origin, to: at(0, -100)) - 180) < 0.01)
        #expect(abs(Geometry.bearing(from: origin, to: at(-100, 0)) - 270) < 0.01)
    }

    @Test func chordBearingIgnoresDogLeg() {
        // Tee at origin, elbow 200 m north, green 200 m north-east of the elbow: chord is 200 E, 400 N.
        let line = [origin, at(0, 200), at(200, 400)]
        let expected = atan2(200.0, 400.0) * 180 / .pi
        #expect(abs(Geometry.chordBearing(of: line)! - expected) < 0.05)
        #expect(Geometry.chordBearing(of: [origin]) == nil)
    }

    @Test func rotatedExtentHeadingNorth() {
        let pts = [at(-50, -200), at(50, 200)]
        let e = Geometry.rotatedExtent(of: pts, heading: 0)!
        #expect(abs(e.width - 100) < 0.1)
        #expect(abs(e.height - 400) < 0.1)
        #expect(Geometry.distance(e.center, origin) < 0.5)
    }

    @Test func rotatedExtentHeadingEastSwapsAxes() {
        let pts = [at(-50, -200), at(50, 200)]
        let e = Geometry.rotatedExtent(of: pts, heading: 90)!
        #expect(abs(e.width - 400) < 0.1)
        #expect(abs(e.height - 100) < 0.1)
    }

    @Test func rotatedExtentOffCentreKeepsGeographicCentre() {
        // A tight box around a point 300 m east: rotation must not move its centre.
        let pts = [at(290, -10), at(310, 10)]
        for heading in [0.0, 45.0, 157.0, 300.0] {
            let e = Geometry.rotatedExtent(of: pts, heading: heading)!
            #expect(Geometry.distance(e.center, at(300, 0)) < 0.5, "heading \(heading)")
        }
    }

    @Test func centroidOfSquare() {
        let c = Geometry.centroid([at(-10, -10), at(10, -10), at(10, 10), at(-10, 10)])!
        #expect(Geometry.distance(c, origin) < 0.01)
    }
}
