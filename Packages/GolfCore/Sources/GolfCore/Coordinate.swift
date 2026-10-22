/// A WGS84 position. Deliberately not CoreLocation's CLLocationCoordinate2D so this
/// package stays free of Apple location frameworks and usable from the extractor
/// tests, a watch build, or a future non-Apple renderer.
public struct Coordinate: Codable, Hashable, Sendable {
    public var latitude: Double
    public var longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    /// Course JSON stores positions as `[longitude, latitude]` pairs (GeoJSON order).
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let lon = try container.decode(Double.self)
        let lat = try container.decode(Double.self)
        self.init(latitude: lat, longitude: lon)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(longitude)
        try container.encode(latitude)
    }
}

/// A closed ring of positions. First and last point need not repeat.
public typealias Polygon = [Coordinate]
