import CoreLocation
import GolfCore
import MapKit
import SwiftUI

/// Camera that shows a whole hole with the green at the top of the screen, fitted into the
/// part of the view not covered by the header and the distance panel.
enum HoleCamera {
    /// Visible ground height is roughly this fraction of the camera distance at pitch 0.
    /// Empirical for MapKit on iPhone; tuned by eye against Prenden.
    static let visibleHeightPerDistance = 0.58
    static let margin = 1.08
    static let minimumDistance: Double = 250

    struct Insets { var top: Double; var bottom: Double }

    static func camera(for hole: Hole, viewSize: CGSize, insets: Insets) -> MapCamera {
        let heading = hole.chordBearing
        guard let extent = Geometry.rotatedExtent(of: hole.allPoints, heading: heading),
              viewSize.width > 0, viewSize.height > 0 else {
            let c = hole.line.first ?? Coordinate(latitude: 0, longitude: 0)
            return MapCamera(centerCoordinate: c.cl, distance: 600, heading: heading, pitch: 0)
        }
        let h = Double(viewSize.height), w = Double(viewSize.width)
        let usable = max(h - insets.top - insets.bottom, h * 0.3)
        let k = visibleHeightPerDistance
        let byHeight = extent.height * (h / usable) / k
        let byWidth = extent.width * (h / w) / k
        let distance = max(max(byHeight, byWidth) * margin, minimumDistance)

        // Shift the camera centre so the hole's centre sits in the middle of the usable band.
        let metresPerPoint = k * distance / h
        let shiftPoints = (insets.bottom - insets.top) / 2
        let shift = shiftPoints * metresPerPoint
        let t = heading * .pi / 180
        let frame = Geometry.LocalFrame(origin: extent.center)
        let centre = frame.coordinate(x: -sin(t) * shift, y: -cos(t) * shift)

        return MapCamera(centerCoordinate: centre.cl, distance: distance, heading: heading, pitch: 0)
    }
}
