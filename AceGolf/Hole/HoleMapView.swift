import GolfCore
import MapKit
import SwiftUI

/// Satellite map of one hole, rotated so the green is at the top, with course overlays.
struct HoleMapView: View {
    let hole: Hole

    @State private var camera: MapCameraPosition = .automatic
    @State private var viewAspect: Double = 0.46

    var body: some View {
        GeometryReader { geo in
            Map(position: $camera, interactionModes: [.pan, .zoom]) {
                ForEach(HoleOverlay.overlays(for: hole)) { o in
                    MapPolygon(coordinates: o.ring)
                        .foregroundStyle(o.fill)
                        .stroke(o.stroke, lineWidth: o.lineWidth)
                }
                MapPolyline(coordinates: hole.line.cl)
                    .stroke(.white.opacity(0.6), style: StrokeStyle(lineWidth: 1.5, dash: [6, 6]))
            }
            .mapStyle(.imagery(elevation: .flat))
            .mapControlVisibility(.hidden)
            .onAppear {
                viewAspect = geo.size.width / max(geo.size.height, 1)
                recentre()
            }
            .onChange(of: hole.number) { recentre() }
            .onChange(of: geo.size) { viewAspect = geo.size.width / max(geo.size.height, 1) }
        }
    }

    private func recentre() {
        withAnimation(.easeInOut(duration: 0.6)) {
            camera = .camera(HoleCamera.camera(for: hole, viewAspect: viewAspect))
        }
    }
}
