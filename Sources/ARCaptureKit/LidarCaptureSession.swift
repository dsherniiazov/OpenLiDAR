import Foundation
import OpenLidarCore

public enum LidarCaptureState: Sendable, Equatable {
    case idle
    case running
    case paused
    case failed(String)
}

public protocol LidarCaptureSessionDelegate: AnyObject {
    func lidarCaptureSession(_ session: LidarCaptureSession, didChangeState state: LidarCaptureState)
    func lidarCaptureSession(_ session: LidarCaptureSession, didProducePointCloud chunk: PointCloudChunk)
}

#if os(iOS) && canImport(ARKit)
import ARKit

public final class LidarCaptureSession: NSObject, ARSessionDelegate {
    public private(set) var state: LidarCaptureState = .idle
    public weak var delegate: LidarCaptureSessionDelegate?

    private let arSession: ARSession
    private var configuration: ScanSessionConfiguration
    private var sequenceNumber: UInt64 = 0
    private var scanID = ScanID()

    public init(configuration: ScanSessionConfiguration) {
        self.configuration = configuration
        self.arSession = ARSession()
        super.init()
        self.arSession.delegate = self
    }

    public func start(scanID: ScanID = ScanID()) throws {
        guard ARWorldTrackingConfiguration.isSupported else {
            throw LidarCaptureSessionError.worldTrackingUnavailable
        }

        self.scanID = scanID
        let arConfiguration = ARWorldTrackingConfiguration()
        arConfiguration.worldAlignment = .gravity

        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification) {
            arConfiguration.sceneReconstruction = .meshWithClassification
        } else if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            arConfiguration.sceneReconstruction = .mesh
        }

        if ARWorldTrackingConfiguration.supportsFrameSemantics(.smoothedSceneDepth) {
            arConfiguration.frameSemantics.insert(.smoothedSceneDepth)
        } else if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            arConfiguration.frameSemantics.insert(.sceneDepth)
        }

        arSession.run(arConfiguration, options: [.resetTracking, .removeExistingAnchors])
        updateState(.running)
    }

    public func pause() {
        arSession.pause()
        updateState(.paused)
    }

    public func session(_ session: ARSession, didFailWithError error: Error) {
        updateState(.failed(error.localizedDescription))
    }

    public func sessionWasInterrupted(_ session: ARSession) {
        updateState(.paused)
    }

    public func sessionInterruptionEnded(_ session: ARSession) {
        if state == .paused {
            try? start(scanID: scanID)
        }
    }

    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard configuration.mode == .lidarSpace else {
            return
        }

        guard let depthData = frame.smoothedSceneDepth ?? frame.sceneDepth,
              let depthMap = DepthPointCloudProjector.copyFloat32DepthMap(depthData.depthMap) else {
            return
        }

        let confidence = depthData.confidenceMap.flatMap(DepthPointCloudProjector.copyUInt8Map)
        let intrinsics = scaledIntrinsics(
            frame.camera.intrinsics,
            cameraResolution: frame.camera.imageResolution,
            depthWidth: depthMap.width,
            depthHeight: depthMap.height
        )

        let pixelStride = strideForPointBudget(
            width: depthMap.width,
            height: depthMap.height,
            maxPointCount: configuration.maxLivePointCount
        )

        let points = DepthPointCloudProjector.project(
            depthMeters: depthMap.values,
            width: depthMap.width,
            height: depthMap.height,
            intrinsics: intrinsics,
            cameraToWorld: frame.camera.transform,
            pixelStride: pixelStride,
            confidence: confidence,
            minimumConfidence: 1,
            minimumDepth: configuration.minimumDepth,
            maximumDepth: configuration.maximumDepth
        )

        sequenceNumber += 1
        let chunk = PointCloudChunk(
            scanID: scanID,
            sequenceNumber: sequenceNumber,
            timestamp: frame.timestamp,
            points: PointCloudDownsampler.strideSample(points, limit: configuration.maxLivePointCount)
        )
        delegate?.lidarCaptureSession(self, didProducePointCloud: chunk)
    }

    private func updateState(_ state: LidarCaptureState) {
        self.state = state
        delegate?.lidarCaptureSession(self, didChangeState: state)
    }

    private func scaledIntrinsics(
        _ matrix: simd_float3x3,
        cameraResolution: CGSize,
        depthWidth: Int,
        depthHeight: Int
    ) -> CameraIntrinsics {
        let scaleX = Float(depthWidth) / Float(cameraResolution.width)
        let scaleY = Float(depthHeight) / Float(cameraResolution.height)

        return CameraIntrinsics(
            fx: matrix[0][0] * scaleX,
            fy: matrix[1][1] * scaleY,
            cx: matrix[2][0] * scaleX,
            cy: matrix[2][1] * scaleY,
            width: depthWidth,
            height: depthHeight
        )
    }

    private func strideForPointBudget(width: Int, height: Int, maxPointCount: Int) -> Int {
        guard maxPointCount > 0 else {
            return 8
        }

        let pixelCount = width * height
        guard pixelCount > maxPointCount else {
            return 1
        }

        return max(1, Int(sqrt(Double(pixelCount) / Double(maxPointCount)).rounded(.up)))
    }
}

#else

public final class LidarCaptureSession {
    public private(set) var state: LidarCaptureState = .idle
    public weak var delegate: LidarCaptureSessionDelegate?

    public init(configuration: ScanSessionConfiguration) {}

    public func start(scanID: ScanID = ScanID()) throws {
        throw LidarCaptureSessionError.unsupportedPlatform
    }

    public func pause() {
        state = .paused
    }
}

#endif

public enum LidarCaptureSessionError: Error, Equatable {
    case unsupportedPlatform
    case worldTrackingUnavailable
}
