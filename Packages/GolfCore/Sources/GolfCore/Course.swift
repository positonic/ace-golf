/// Normalized course model: the contract between the extractor and the app.
/// Schema version 1. See docs/DECISIONS.md.
public struct Course: Codable, Hashable, Sendable {
    public static let currentSchema = 1

    public var schema: Int
    public var id: String
    public var name: String
    public var osm: OSMSource
    public var polygon: Polygon
    public var holes: [Hole]

    public init(schema: Int = Course.currentSchema, id: String, name: String, osm: OSMSource, polygon: Polygon, holes: [Hole]) {
        self.schema = schema
        self.id = id
        self.name = name
        self.osm = osm
        self.polygon = polygon
        self.holes = holes
    }

    public func hole(number: Int) -> Hole? {
        holes.first { $0.number == number }
    }
}

/// Where the course came from, so fixes can be pushed back upstream.
public struct OSMSource: Codable, Hashable, Sendable {
    public var courseWay: Int64
    public var holeWays: [Int64]

    public init(courseWay: Int64, holeWays: [Int64]) {
        self.courseWay = courseWay
        self.holeWays = holeWays
    }
}

public struct Hole: Codable, Hashable, Sendable {
    public var number: Int
    public var par: Int?
    public var handicap: Int?
    /// The OSM `golf=hole` centreline, tee first, green last.
    public var line: [Coordinate]
    public var green: Polygon
    public var tees: [Polygon]
    public var fairways: [Polygon]
    public var bunkers: [Polygon]
    public var water: [Polygon]

    public init(number: Int, par: Int? = nil, handicap: Int? = nil, line: [Coordinate], green: Polygon,
                tees: [Polygon] = [], fairways: [Polygon] = [], bunkers: [Polygon] = [], water: [Polygon] = []) {
        self.number = number
        self.par = par
        self.handicap = handicap
        self.line = line
        self.green = green
        self.tees = tees
        self.fairways = fairways
        self.bunkers = bunkers
        self.water = water
    }
}
