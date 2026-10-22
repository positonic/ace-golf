import CoreLocation
import Foundation
import GolfCore
import Observation

/// Foreground-only GPS. Best accuracy, fitness activity, no smoothing: the latest fix is
/// shown as-is, with its accuracy. Every fix is appended to a JSON-lines log in Documents/logs
/// so a real round can be replayed later.
@MainActor
@Observable
final class LocationService {
    private(set) var latest: LocationFix?
    private(set) var isDenied = false
    private(set) var logURL: URL?

    private var task: Task<Void, Never>?
    private var logHandle: FileHandle?

    func start() {
        guard task == nil else { return }
        openLog()
        task = Task { [weak self] in
            do {
                for try await update in CLLocationUpdate.liveUpdates(.fitness) {
                    guard let self, !Task.isCancelled else { return }
                    if update.authorizationDenied || update.authorizationDeniedGlobally {
                        self.isDenied = true
                    }
                    if let location = update.location {
                        self.record(location)
                    }
                }
            } catch {
                // Cancelled or the system stopped updates; the UI shows "waiting" until restarted.
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
        try? logHandle?.close()
        logHandle = nil
    }

    private func record(_ location: CLLocation) {
        let fix = LocationFix(
            t: location.timestamp,
            lat: location.coordinate.latitude,
            lon: location.coordinate.longitude,
            acc: location.horizontalAccuracy,
            alt: location.verticalAccuracy >= 0 ? location.altitude : nil,
            speed: location.speed >= 0 ? location.speed : nil,
            course: location.course >= 0 ? location.course : nil
        )
        latest = fix
        if let handle = logHandle, let line = try? fix.jsonLine() {
            try? handle.write(contentsOf: Data(line.utf8))
        }
    }

    private func openLog() {
        guard logHandle == nil else { return }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("logs", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let stamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "")
        let url = dir.appendingPathComponent("location-\(stamp).jsonl")
        if !FileManager.default.fileExists(atPath: url.path) {
            FileManager.default.createFile(atPath: url.path, contents: nil)
        }
        logHandle = try? FileHandle(forWritingTo: url)
        _ = try? logHandle?.seekToEnd()
        logURL = url
    }
}
