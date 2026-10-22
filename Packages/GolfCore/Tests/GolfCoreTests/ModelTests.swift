import Foundation
import Testing
@testable import GolfCore

@Suite struct ModelTests {
    @Test func coordinateDecodesFromLonLatPair() throws {
        let data = Data("[13.5676, 52.7850]".utf8)
        let c = try JSONDecoder().decode(Coordinate.self, from: data)
        #expect(c.latitude == 52.7850)
        #expect(c.longitude == 13.5676)
    }

    @Test func courseRoundTripsThroughCodable() throws {
        let hole = Hole(number: 1, par: 4,
                        line: [Coordinate(latitude: 52.78, longitude: 13.56), Coordinate(latitude: 52.79, longitude: 13.57)],
                        green: [Coordinate(latitude: 52.79, longitude: 13.57)])
        let course = Course(id: "osm-way-1", name: "Test", osm: OSMSource(courseWay: 1, holeWays: [2]),
                            polygon: [], holes: [hole])
        let data = try JSONEncoder().encode(course)
        let decoded = try JSONDecoder().decode(Course.self, from: data)
        #expect(decoded == course)
        #expect(decoded.hole(number: 1)?.par == 4)
    }

    @Test func newRoundHasEmptyShotsPerHole() {
        let course = Course(id: "c", name: "C", osm: OSMSource(courseWay: 1, holeWays: []), polygon: [],
                            holes: (1...18).map { Hole(number: $0, line: [], green: []) })
        let round = Round.new(for: course)
        #expect(round.holes.count == 18)
        #expect(round.holes.allSatisfy { $0.shots.isEmpty && $0.strokes == nil })
    }
}
