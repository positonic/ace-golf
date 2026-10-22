import Foundation

/// One played round. Schema version 1. `shots` is reserved for manual and automatic
/// shot marking in later features; it is always present so no migration is needed.
public struct Round: Codable, Hashable, Sendable {
    public static let currentSchema = 1

    public var schema: Int
    public var courseId: String
    public var startedAt: Date
    public var holes: [HoleScore]

    public init(schema: Int = Round.currentSchema, courseId: String, startedAt: Date, holes: [HoleScore]) {
        self.schema = schema
        self.courseId = courseId
        self.startedAt = startedAt
        self.holes = holes
    }

    public static func new(for course: Course, at date: Date = Date()) -> Round {
        Round(courseId: course.id, startedAt: date,
              holes: course.holes.map { HoleScore(number: $0.number) })
    }
}

public struct HoleScore: Codable, Hashable, Sendable {
    public var number: Int
    public var strokes: Int?
    public var shots: [Shot]

    public init(number: Int, strokes: Int? = nil, shots: [Shot] = []) {
        self.number = number
        self.strokes = strokes
        self.shots = shots
    }
}

public struct Shot: Codable, Hashable, Sendable {
    public var time: Date
    public var position: Coordinate
    public var accuracy: Double

    public init(time: Date, position: Coordinate, accuracy: Double) {
        self.time = time
        self.position = position
        self.accuracy = accuracy
    }
}
