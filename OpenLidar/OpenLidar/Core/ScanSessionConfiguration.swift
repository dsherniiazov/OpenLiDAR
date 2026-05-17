import Foundation

public enum StreamingTransport: String, Codable, Sendable, CaseIterable {
    case disabled
    case osc
    case udpBinary
    case websocket
}

public struct ScanSessionConfiguration: Codable, Sendable, Equatable {
    public var mode: ScanMode
    public var targetFramesPerSecond: Int
    public var maxLivePointCount: Int
    public var minimumDepth: Float
    public var maximumDepth: Float
    public var streamingTransport: StreamingTransport
    public var receiverHost: String?
    public var receiverPort: UInt16?

    public init(
        mode: ScanMode,
        targetFramesPerSecond: Int = 30,
        maxLivePointCount: Int = 100_000,
        minimumDepth: Float = 0.2,
        maximumDepth: Float = 5.0,
        streamingTransport: StreamingTransport = .disabled,
        receiverHost: String? = nil,
        receiverPort: UInt16? = nil
    ) {
        self.mode = mode
        self.targetFramesPerSecond = targetFramesPerSecond
        self.maxLivePointCount = maxLivePointCount
        self.minimumDepth = minimumDepth
        self.maximumDepth = maximumDepth
        self.streamingTransport = streamingTransport
        self.receiverHost = receiverHost
        self.receiverPort = receiverPort
    }
}

public enum CaptureCapability: String, Codable, Sendable, CaseIterable {
    case worldTracking
    case sceneDepth
    case smoothedSceneDepth
    case lidarMeshReconstruction
    case roomPlan
    case objectCapture
}

public struct DeviceCapabilities: Codable, Sendable, Equatable {
    public var supported: Set<CaptureCapability>

    public init(supported: Set<CaptureCapability>) {
        self.supported = supported
    }

    public func supports(_ capability: CaptureCapability) -> Bool {
        supported.contains(capability)
    }
}
