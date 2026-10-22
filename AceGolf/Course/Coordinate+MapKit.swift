import CoreLocation
import GolfCore

extension Coordinate {
    var cl: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: latitude, longitude: longitude) }
}

extension Array where Element == Coordinate {
    var cl: [CLLocationCoordinate2D] { map(\.cl) }
}
