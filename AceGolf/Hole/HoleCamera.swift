import CoreLocation
import GolfCore
import MapKit
import SwiftUI

/// Camera that shows a whole hole with the green at the top of the screen.
enum HoleCamera {
    /// Visible ground height is roughly this fraction of the camera distance at pitch 0.
    /// Empirical for MapKit on iPhone; tuned by eye against Prenden.
    static let visibleHeightPerDistance = 0.45
    static let margin = 1.25
    static let minimumDistance: Double = 250

    static func camera(for hole: Hole, viewAspect: Double) -> MapCamera {
        let heading = hole.chordBearing
        guard let extent = Geometry.rotatedExtent(of: hole.allPoints, heading: heading) else {
            let c = hole.line.first ?? Coordinate(latitude: 0, longitude: 0)
            return MapCamera(centerCoordinate: c.cl, distance: 600, heading: heading, pitch: 0)
        }
        let byHeight = extent.height / visibleHeightPerDistance
        let byWidth = extent.width / (visibleHeightPerDistance * max(viewAspect, 0.1))
        let distance = max(byHeight, byWidth) * margin
        return MapCamera(centerCoordinate: extent.center.cl,
                         distance: max(distance, minimumDistance),
                         heading: heading, pitch: 0)
    }
}
