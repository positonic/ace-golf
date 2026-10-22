import Foundation
import GolfCore
import Observation

/// The current round, persisted as JSON in Documents/rounds. One file per round, named by start time;
/// `current.json` is a copy of the round in progress so relaunch restores it.
@MainActor
@Observable
final class RoundStore {
    private(set) var round: Round
    private let course: Course

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()
    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    static var directory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("rounds", isDirectory: true)
    }
    static var currentURL: URL { directory.appendingPathComponent("current.json") }

    init(course: Course) {
        self.course = course
        if let data = try? Data(contentsOf: Self.currentURL),
           let saved = try? Self.decoder.decode(Round.self, from: data),
           saved.courseId == course.id {
            round = saved
        } else {
            round = Round.new(for: course)
        }
    }

    func setStrokes(_ strokes: Int?, hole: Int) {
        round.setStrokes(strokes, hole: hole)
        save()
    }

    func adjustStrokes(hole: Int, by delta: Int) {
        let current = round.strokes(hole: hole)
        let par = course.hole(number: hole)?.par ?? 4
        // First tap on an unscored hole starts from par, so a par is one tap and a bogey two.
        let next = (current ?? (delta > 0 ? par - 1 : par + 1)) + delta
        setStrokes(next, hole: hole)
    }

    func startNewRound() {
        round = Round.new(for: course)
        save()
    }

    var totalStrokes: Int { round.totalStrokes }
    var toPar: Int? { round.toPar(on: course) }

    private func save() {
        do {
            try FileManager.default.createDirectory(at: Self.directory, withIntermediateDirectories: true)
            let data = try Self.encoder.encode(round)
            try data.write(to: Self.currentURL, options: .atomic)
            let stamp = ISO8601DateFormatter().string(from: round.startedAt).replacingOccurrences(of: ":", with: "")
            try data.write(to: Self.directory.appendingPathComponent("round-\(stamp).json"), options: .atomic)
        } catch {
            // Persistence is best effort on the course; the in-memory round still works.
        }
    }
}
