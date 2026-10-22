// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GolfCore",
    platforms: [.iOS(.v18), .macOS(.v14)],
    products: [
        .library(name: "GolfCore", targets: ["GolfCore"]),
    ],
    targets: [
        .target(name: "GolfCore"),
        .testTarget(name: "GolfCoreTests", dependencies: ["GolfCore"]),
    ]
)
