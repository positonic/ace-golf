import Foundation
import GolfCore

/// Loads course files bundled with the app. Round one bundles a single course and makes no network calls.
enum CourseStore {
    static func loadBundled(_ name: String) throws -> Course {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile, userInfo: [NSFilePathErrorKey: "\(name).json"])
        }
        return try JSONDecoder().decode(Course.self, from: Data(contentsOf: url))
    }
}
