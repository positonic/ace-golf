import GolfCore
import MapKit
import SwiftUI

/// Satellite map of one hole, rotated so the green is at the top, with course overlays.
struct HoleMapView: View {
    let hole: Hole
    var fix: LocationFix? = nil
    /// Points covered by the header and the distance panel, so the hole is fitted between them.
    var insets = HoleCamera.Insets(top: 130, bottom: 200)

    @State private var camera: MapCameraPosition = .automatic
    @State private var viewSize: CGSize = .zero

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
                if let fix {
                    if fix.acc > 0 {
                        MapCircle(center: fix.coordinate.cl, radius: fix.acc)
                            .foregroundStyle(.blue.opacity(0.15))
                            .stroke(.blue.opacity(0.6), lineWidth: 1)
                    }
                    Annotation("", coordinate: fix.coordinate.cl, anchor: .center) {
                        ZStack {
                            Circle().fill(.white).frame(width: 20, height: 20)
                            Circle().fill(.blue).frame(width: 14, height: 14)
                        }
                        .shadow(radius: 2)
                    }
                    .annotationTitles(.hidden)
                }
            }
            .mapStyle(.imagery(elevation: .flat))
            .mapControlVisibility(.hidden)
            .onAppear {
                viewSize = geo.size
                recentre()
            }
            .onChange(of: hole.number) { recentre() }
            .onChange(of: geo.size) { viewSize = geo.size }
        }
    }

    private func recentre() {
        withAnimation(.easeInOut(duration: 0.6)) {
            camera = .camera(HoleCamera.camera(for: hole, viewSize: viewSize, insets: insets))
        }
    }
}
