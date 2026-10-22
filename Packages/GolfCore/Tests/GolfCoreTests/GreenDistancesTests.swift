import Foundation
import Testing
@testable import GolfCore

@Suite struct GreenDistancesTests {
    let origin = Coordinate(latitude: 52.78, longitude: 13.57)
    func at(_ x: Double, _ y: Double) -> Coordinate {
        Geometry.LocalFrame(origin: origin).coordinate(x: x, y: y)
    }
    /// 30 m square green centred 200 m north of the origin.
    var green: Polygon { [at(-15, 185), at(15, 185), at(15, 215), at(-15, 215)] }

    @Test func fromTheSouth() {
        let d = GreenDistances.from(origin, to: green)!
        #expect(abs(d.front - 185) < 0.2)
        #expect(abs(d.middle - 200) < 0.2)
        #expect(abs(d.back - 215) < 0.2)
    }

    @Test func fromTheEastSeesTheNarrowAxis() {
        let d = GreenDistances.from(at(100, 200), to: green)!
        #expect(abs(d.front - 85) < 0.2)
        #expect(abs(d.middle - 100) < 0.2)
        #expect(abs(d.back - 115) < 0.2)
    }

    @Test func fromADiagonalProjectsTheCorners() {
        // 141.42 m from the centroid along the NE diagonal; corners project at ±15*sqrt(2).
        let d = GreenDistances.from(at(100, 300), to: green)!
        let m = (100.0 * 100 + 100 * 100).squareRoot()
        let half = 15 * 2.0.squareRoot()
        #expect(abs(d.middle - m) < 0.2)
        #expect(abs(d.front - (m - half)) < 0.2)
        #expect(abs(d.back - (m + half)) < 0.2)
        #expect(d.front <= d.middle && d.middle <= d.back)
    }

    @Test func onTheGreenClampsToZero() {
        let d = GreenDistances.from(at(10, 200), to: green)!
        #expect(d.front == 0)
        #expect(abs(d.middle - 10) < 0.2)
        #expect(abs(d.back - 25) < 0.2)
    }

    @Test func degenerateGreenIsNil() {
        #expect(GreenDistances.from(origin, to: [origin]) == nil)
    }

    @Test func locationFixRoundTripsAsJSONLine() throws {
        let fix = LocationFix(t: Date(timeIntervalSince1970: 1_800_000_000), lat: 52.78, lon: 13.57, acc: 4.5, alt: 60, speed: 1.3)
        let line = try fix.jsonLine()
        #expect(line.hasSuffix("\n"))
        let back = try LocationFix.lineDecoder.decode(LocationFix.self, from: Data(line.utf8))
        #expect(back == fix)
        #expect(fix.isPrecise)
        #expect(!LocationFix(t: fix.t, lat: 0, lon: 0, acc: 30).isPrecise)
    }
}
