import Foundation

/// Pure spherical and local-plane geometry. No MapKit, no CoreLocation.
public enum Geometry {
    public static let earthRadius = 6_371_008.8

    /// Great-circle distance in metres.
    public static func distance(_ a: Coordinate, _ b: Coordinate) -> Double {
        let lat1 = a.latitude * .pi / 180, lat2 = b.latitude * .pi / 180
        let dLat = lat2 - lat1
        let dLon = (b.longitude - a.longitude) * .pi / 180
        let h = sin(dLat / 2) * sin(dLat / 2) + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        return 2 * earthRadius * asin(min(1, sqrt(h)))
    }

    /// Initial compass bearing from `a` to `b`, degrees in [0, 360).
    public static func bearing(from a: Coordinate, to b: Coordinate) -> Double {
        let lat1 = a.latitude * .pi / 180, lat2 = b.latitude * .pi / 180
        let dLon = (b.longitude - a.longitude) * .pi / 180
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let deg = atan2(y, x) * 180 / .pi
        return (deg + 360).truncatingRemainder(dividingBy: 360)
    }

    /// Chord bearing of a hole: first point of the centreline to the last. Dog-legs are ignored by design.
    public static func chordBearing(of line: [Coordinate]) -> Double? {
        guard let first = line.first, let last = line.last, line.count >= 2 else { return nil }
        return bearing(from: first, to: last)
    }

    /// Arithmetic mean of a ring's vertices. Adequate for greens and tees at course scale.
    public static func centroid(_ ring: [Coordinate]) -> Coordinate? {
        guard !ring.isEmpty else { return nil }
        let n = Double(ring.count)
        return Coordinate(latitude: ring.map(\.latitude).reduce(0, +) / n,
                          longitude: ring.map(\.longitude).reduce(0, +) / n)
    }

    /// Equirectangular metres-east / metres-north frame around an origin. Good to well under a metre at course scale.
    public struct LocalFrame: Sendable {
        public let origin: Coordinate
        private let kx: Double
        private let ky: Double

        public init(origin: Coordinate) {
            self.origin = origin
            ky = Geometry.earthRadius * .pi / 180
            kx = ky * cos(origin.latitude * .pi / 180)
        }

        public func xy(_ c: Coordinate) -> (x: Double, y: Double) {
            ((c.longitude - origin.longitude) * kx, (c.latitude - origin.latitude) * ky)
        }

        public func coordinate(x: Double, y: Double) -> Coordinate {
            Coordinate(latitude: origin.latitude + y / ky, longitude: origin.longitude + x / kx)
        }
    }

    /// Extent of a point set in a frame rotated so that `heading` (compass degrees) points "up".
    /// Returns the geographic centre of that rotated bounding box and its width (across) and height (along heading) in metres.
    public struct RotatedExtent: Sendable, Equatable {
        public var center: Coordinate
        public var width: Double
        public var height: Double
    }

    public static func rotatedExtent(of points: [Coordinate], heading: Double) -> RotatedExtent? {
        guard let origin = centroid(points) else { return nil }
        let frame = LocalFrame(origin: origin)
        let t = heading * .pi / 180
        let s = sin(t), c = cos(t)
        var minU = Double.infinity, maxU = -Double.infinity, minV = Double.infinity, maxV = -Double.infinity
        for p in points {
            let (x, y) = frame.xy(p)
            let v = x * s + y * c   // along heading ("up")
            let u = x * c - y * s   // to the right of heading
            minU = min(minU, u); maxU = max(maxU, u)
            minV = min(minV, v); maxV = max(maxV, v)
        }
        let cu = (minU + maxU) / 2, cv = (minV + maxV) / 2
        let cx = cu * c + cv * s
        let cy = -cu * s + cv * c
        return RotatedExtent(center: frame.coordinate(x: cx, y: cy), width: maxU - minU, height: maxV - minV)
    }
}

public extension Hole {
    /// Every vertex that should be visible when the hole is shown.
    var allPoints: [Coordinate] {
        line + green + tees.flatMap(\.polygon) + fairways.flatMap { $0 } + bunkers.flatMap { $0 } + water.flatMap { $0 }
    }

    var chordBearing: Double { Geometry.chordBearing(of: line) ?? 0 }
}
