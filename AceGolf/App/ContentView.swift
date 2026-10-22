import GolfCore
import SwiftUI

struct ContentView: View {
    private let course: Result<Course, Error> = Result { try CourseStore.loadBundled("prenden") }

    /// Debug hook: `-hole 8` as a launch argument opens on hole 8. Defaults to hole 1.
    private var initialHole: Int {
        let n = UserDefaults.standard.integer(forKey: "hole")
        return n > 0 ? n : 1
    }

    var body: some View {
        switch course {
        case .success(let course):
            HoleScreen(course: course, initialHole: initialHole)
        case .failure(let error):
            ContentUnavailableView("Course data missing", systemImage: "map",
                                   description: Text(error.localizedDescription))
        }
    }
}
