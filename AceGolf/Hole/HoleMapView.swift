import MapKit
import SwiftUI

/// Satellite map. Scaffold version: centred on Golfclub Prenden with no course data yet.
/// Hole overlays, rotation and distances arrive in later tickets.
struct HoleMapView: View {
    /// Golfclub Prenden clubhouse (OSM way 4756114). Replaced by the course polygon centroid once course data is bundled.
    private static let prenden = CLLocationCoordinate2D(latitude: 52.7850, longitude: 13.5676)

    @State private var camera: MapCameraPosition = .camera(
        MapCamera(centerCoordinate: prenden, distance: 2500, heading: 0, pitch: 0)
    )

    var body: some View {
        Map(position: $camera) {
        }
        .mapStyle(.imagery(elevation: .flat))
        .mapControlVisibility(.hidden)
    }
}

#Preview {
    HoleMapView()
}
