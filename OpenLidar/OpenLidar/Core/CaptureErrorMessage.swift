import Foundation

struct CaptureErrorMessage: Equatable {
    var title: String
    var message: String

    static func from(_ error: Error) -> CaptureErrorMessage {
        if let captureError = error as? LidarCaptureSessionError {
            return from(captureError)
        }

        return fromRawReason(error.localizedDescription)
    }

    static func from(_ error: LidarCaptureSessionError) -> CaptureErrorMessage {
        switch error {
        case .unsupportedPlatform:
            CaptureErrorMessage(
                title: "Scanning is unavailable",
                message: "OpenLidar can capture LiDAR scans only on supported iOS or iPadOS devices."
            )
        case .worldTrackingUnavailable:
            CaptureErrorMessage(
                title: "AR tracking is unavailable",
                message: "This device cannot start AR world tracking, so OpenLidar cannot place scan points in 3D space."
            )
        }
    }

    static func fromRawReason(_ reason: String) -> CaptureErrorMessage {
        let normalized = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else {
            return generic
        }

        let lowercased = normalized.lowercased()

        if lowercased.contains("camera") || lowercased.contains("authorization") || lowercased.contains("permission") {
            return CaptureErrorMessage(
                title: "Camera access is needed",
                message: "Allow camera access in Settings so OpenLidar can read AR camera and depth frames."
            )
        }

        if lowercased.contains("tracking") {
            return CaptureErrorMessage(
                title: "Tracking was interrupted",
                message: "Move slowly in a well-lit area with visible surfaces, then restart the scan."
            )
        }

        return CaptureErrorMessage(
            title: "Scan failed",
            message: "OpenLidar could not start or continue the AR session. \(normalized)"
        )
    }

    static let generic = CaptureErrorMessage(
        title: "Scan failed",
        message: "OpenLidar could not start or continue the AR session. Try restarting the scan."
    )
}
