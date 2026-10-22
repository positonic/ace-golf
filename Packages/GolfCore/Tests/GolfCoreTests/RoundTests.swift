import Foundation
import Testing
@testable import GolfCore

@Suite struct RoundTests {
    func course(pars: [Int?]) -> Course {
        Course(id: "c", name: "C", osm: OSMSource(courseWay: 1, holeWays: []), polygon: [],
               holes: pars.enumerated().map { Hole(number: $0.offset + 1, par: $0.element, line: [], green: []) })
    }

    @Test func totalsAndToPar() {
        let c = course(pars: [4, 3, 5, 4])
        var r = Round.new(for: c)
        r.setStrokes(5, hole: 1)
        r.setStrokes(3, hole: 2)
        r.setStrokes(7, hole: 3)
        #expect(r.totalStrokes == 15)
        #expect(r.playedHoleCount == 3)
        #expect(r.toPar(on: c) == 3)
        #expect(formatToPar(3) == "+3")
        #expect(formatToPar(0) == "E")
        #expect(formatToPar(-2) == "-2")
    }

    @Test func toParIsNilWhenAPlayedHoleHasNoPar() {
        let c = course(pars: [4, nil, 5])
        var r = Round.new(for: c)
        r.setStrokes(4, hole: 1)
        #expect(r.toPar(on: c) == 0)
        r.setStrokes(4, hole: 2)
        #expect(r.toPar(on: c) == nil)
    }

    @Test func strokesAreClampedAndClearable() {
        let c = course(pars: [4])
        var r = Round.new(for: c)
        r.setStrokes(0, hole: 1)
        #expect(r.strokes(hole: 1) == 1)
        r.setStrokes(99, hole: 1)
        #expect(r.strokes(hole: 1) == 20)
        r.setStrokes(nil, hole: 1)
        #expect(r.strokes(hole: 1) == nil)
        r.setStrokes(4, hole: 7) // unknown hole is ignored
        #expect(r.totalStrokes == 0)
    }

    @Test func roundFileRoundTripsWithEmptyShots() throws {
        let c = course(pars: [4, 4])
        var r = Round.new(for: c, at: Date(timeIntervalSince1970: 1_800_000_000))
        r.setStrokes(4, hole: 2)
        let enc = JSONEncoder(); enc.dateEncodingStrategy = .iso8601
        let dec = JSONDecoder(); dec.dateDecodingStrategy = .iso8601
        let data = try enc.encode(r)
        let json = String(decoding: data, as: UTF8.self)
        #expect(json.contains("\"shots\":[]"))
        #expect(try dec.decode(Round.self, from: data) == r)
    }
}
