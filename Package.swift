// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "OpenLidar",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "OpenLidarCore", targets: ["OpenLidarCore"]),
        .library(name: "ARCaptureKit", targets: ["ARCaptureKit"]),
        .library(name: "ScanStreaming", targets: ["ScanStreaming"]),
        .library(name: "ScanExport", targets: ["ScanExport"]),
        .executable(name: "openlidar", targets: ["OpenLidarCLI"])
    ],
    targets: [
        .target(name: "OpenLidarCore"),
        .target(name: "ARCaptureKit", dependencies: ["OpenLidarCore"]),
        .target(name: "ScanStreaming", dependencies: ["OpenLidarCore"]),
        .target(name: "ScanExport", dependencies: ["OpenLidarCore"]),
        .executableTarget(
            name: "OpenLidarCLI",
            dependencies: ["OpenLidarCore", "ScanExport", "ScanStreaming"]
        ),
        .testTarget(name: "OpenLidarCoreTests", dependencies: ["OpenLidarCore"]),
        .testTarget(name: "ScanStreamingTests", dependencies: ["ScanStreaming"]),
        .testTarget(name: "ScanExportTests", dependencies: ["ScanExport"])
    ]
)
