import Foundation

/// Front, middle and back distances from a position to a green, in metres.
///
/// Middle is the great-circle distance to the green's centroid. Front and back are the
/// green boundary vertices with the smallest and largest projection onto the line from
/// the position to the centroid, so they are correct from any approach direction,
/// including a side approach. Values are clamped at zero when standing on the green.
public struct GreenDistances: Equatable, Sendable {
    public var front: Double
    public var middle: Double
    public var back: Double

    public init(front: Double, middle: Double, back: Double) {
        self.front = front
        self.middle = middle
        self.back = back
    }

    public static func from(_ position: Coordinate, to green: Polygon) -> GreenDistances? {
        guard green.count >= 3, let centre = Geometry.centroid(green) else { return nil }
        let frame = Geometry.LocalFrame(origin: position)
        let (cx, cy) = frame.xy(centre)
        let middle = (cx * cx + cy * cy).squareRoot()
        guard middle > 0.01 else {
            // Standing on the centroid: no direction to project along.
            return GreenDistances(front: 0, middle: 0, back: 0)
        }
        let dx = cx / middle, dy = cy / middle
        var minP = Double.infinity, maxP = -Double.infinity
        for v in green {
            let (x, y) = frame.xy(v)
            let p = x * dx + y * dy
            minP = min(minP, p)
            maxP = max(maxP, p)
        }
        return GreenDistances(front: max(0, minP), middle: middle, back: max(0, maxP))
    }
}
