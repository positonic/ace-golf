import Foundation

/// One GPS fix as logged during a round. One JSON object per line in the location log.
/// Kept framework-free so logs can be replayed in tests and by the extractor tooling.
public struct LocationFix: Codable, Hashable, Sendable {
    public var t: Date
    public var lat: Double
    public var lon: Double
    /// Horizontal accuracy radius in metres (68% confidence), negative when invalid.
    public var acc: Double
    public var alt: Double?
    public var speed: Double?
    public var course: Double?

    public init(t: Date, lat: Double, lon: Double, acc: Double, alt: Double? = nil, speed: Double? = nil, course: Double? = nil) {
        self.t = t
        self.lat = lat
        self.lon = lon
        self.acc = acc
        self.alt = alt
        self.speed = speed
        self.course = course
    }

    public var coordinate: Coordinate { Coordinate(latitude: lat, longitude: lon) }

    /// Accuracy beyond which the UI dims distance values.
    public static let dimThresholdMetres = 15.0
    public var isPrecise: Bool { acc >= 0 && acc <= Self.dimThresholdMetres }

    public static let lineEncoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return e
    }()

    public static let lineDecoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    public func jsonLine() throws -> String {
        String(decoding: try Self.lineEncoder.encode(self), as: UTF8.self) + "\n"
    }
}
