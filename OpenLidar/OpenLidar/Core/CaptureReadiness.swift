import Foundation

struct CaptureReadiness: Equatable {
    var canStartCapture: Bool
    var title: String
    var message: String
    var missingCapabilities: [CaptureCapability]

    static func lidarSpace(capabilities: DeviceCapabilities) -> CaptureReadiness {
        var missing: [CaptureCapability] = []

        if !capabilities.supports(.worldTracking) {
            missing.append(.worldTracking)
        }

        if !capabilities.supports(.sceneDepth) && !capabilities.supports(.smoothedSceneDepth) {
            missing.append(.sceneDepth)
        }

        if missing.isEmpty {
            return CaptureReadiness(
                canStartCapture: true,
                title: "Ready to scan",
                message: "This device supports AR world tracking and depth capture.",
                missingCapabilities: []
            )
        }

        if missing.contains(.worldTracking) {
            return CaptureReadiness(
                canStartCapture: false,
                title: "AR tracking unavailable",
                message: "OpenLidar needs AR world tracking to place captured points in 3D space. Try a supported iPhone or iPad.",
                missingCapabilities: missing
            )
        }

        return CaptureReadiness(
            canStartCapture: false,
            title: "LiDAR depth unavailable",
            message: "OpenLidar needs scene depth from a LiDAR-capable iPhone or iPad to capture point clouds.",
            missingCapabilities: missing
        )
    }
}
