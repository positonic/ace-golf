import Foundation
import Testing
@testable import GolfCore

/// Decodes the real bundled extract. Guards the extractor-to-app contract.
@Suite struct PrendenExtractTests {
    static var fileURL: URL {
        // Tests/GolfCoreTests/<file> -> Packages/GolfCore -> repo root
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { url.deleteLastPathComponent() }
        return url.appendingPathComponent("data/courses/prenden.json")
    }

    static func load() throws -> Course {
        try JSONDecoder().decode(Course.self, from: Data(contentsOf: fileURL))
    }

    @Test func decodesEighteenHolesEachWithAGreen() throws {
        let course = try Self.load()
        #expect(course.schema == Course.currentSchema)
        #expect(course.name == "Golfclub Prenden")
        #expect(course.holes.map(\.number) == Array(1...18))
        #expect(course.holes.allSatisfy { $0.green.count >= 3 })
        #expect(course.holes.allSatisfy { $0.line.count >= 2 })
    }

    @Test func parTotalIs72() throws {
        let course = try Self.load()
        #expect(course.holes.compactMap(\.par).reduce(0, +) == 72)
    }

    @Test func coordinatesAreInBrandenburg() throws {
        let course = try Self.load()
        for hole in course.holes {
            for c in hole.line + hole.green {
                #expect(c.latitude > 52.77 && c.latitude < 52.80)
                #expect(c.longitude > 13.55 && c.longitude < 13.59)
            }
        }
    }

    @Test func teeNamesSurviveExtraction() throws {
        let course = try Self.load()
        let named = course.holes.flatMap(\.tees).compactMap(\.name)
        #expect(!named.isEmpty)
        #expect(named.contains("Abschlag Gelb"))
    }
}
