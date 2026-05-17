import Foundation
import simd

public struct ScanID: Hashable, Codable, Sendable, RawRepresentable {
    public let rawValue: UUID

    public init(rawValue: UUID) {
        self.rawValue = rawValue
    }

    public init() {
        self.rawValue = UUID()
    }
}

public enum ScanMode: String, Codable, Sendable {
    case lidarSpace
    case roomPlan
    case objectCapture
    case gaussianSplatDataset
}

public struct ScanMetadata: Codable, Sendable, Equatable {
    public var id: ScanID
    public var name: String
    public var mode: ScanMode
    public var createdAt: Date
    public var appVersion: String
    public var deviceModel: String

    public init(
        id: ScanID = ScanID(),
        name: String,
        mode: ScanMode,
        createdAt: Date = Date(),
        appVersion: String,
        deviceModel: String
    ) {
        self.id = id
        self.name = name
        self.mode = mode
        self.createdAt = createdAt
        self.appVersion = appVersion
        self.deviceModel = deviceModel
    }
}

public struct CameraIntrinsics: Codable, Sendable, Equatable {
    public var fx: Float
    public var fy: Float
    public var cx: Float
    public var cy: Float
    public var width: Int
    public var height: Int

    public init(fx: Float, fy: Float, cx: Float, cy: Float, width: Int, height: Int) {
        self.fx = fx
        self.fy = fy
        self.cx = cx
        self.cy = cy
        self.width = width
        self.height = height
    }
}

public struct CameraPose: Codable, Sendable, Equatable {
    public var timestamp: TimeInterval
    public var transform: simd_float4x4

    public init(timestamp: TimeInterval, transform: simd_float4x4) {
        self.timestamp = timestamp
        self.transform = transform
    }
}

public struct PointXYZRGBA: Codable, Sendable, Equatable {
    public var x: Float
    public var y: Float
    public var z: Float
    public var red: UInt8
    public var green: UInt8
    public var blue: UInt8
    public var alpha: UInt8
    public var confidence: UInt8

    public init(
        x: Float,
        y: Float,
        z: Float,
        red: UInt8 = 255,
        green: UInt8 = 255,
        blue: UInt8 = 255,
        alpha: UInt8 = 255,
        confidence: UInt8 = 255
    ) {
        self.x = x
        self.y = y
        self.z = z
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
        self.confidence = confidence
    }
}

public struct PointCloudChunk: Codable, Sendable, Equatable {
    public var scanID: ScanID
    public var sequenceNumber: UInt64
    public var timestamp: TimeInterval
    public var points: [PointXYZRGBA]

    public init(
        scanID: ScanID,
        sequenceNumber: UInt64,
        timestamp: TimeInterval,
        points: [PointXYZRGBA]
    ) {
        self.scanID = scanID
        self.sequenceNumber = sequenceNumber
        self.timestamp = timestamp
        self.points = points
    }
}

public struct AxisAlignedBounds: Codable, Sendable, Equatable {
    public var minimum: SIMD3<Float>
    public var maximum: SIMD3<Float>

    public init(minimum: SIMD3<Float>, maximum: SIMD3<Float>) {
        self.minimum = minimum
        self.maximum = maximum
    }

    public var dimensions: SIMD3<Float> {
        maximum - minimum
    }

    public static func enclosing(_ points: some Collection<PointXYZRGBA>) -> AxisAlignedBounds? {
        guard let first = points.first else {
            return nil
        }

        var minPoint = SIMD3<Float>(first.x, first.y, first.z)
        var maxPoint = minPoint

        for point in points.dropFirst() {
            let current = SIMD3<Float>(point.x, point.y, point.z)
            minPoint = simd.min(minPoint, current)
            maxPoint = simd.max(maxPoint, current)
        }

        return AxisAlignedBounds(minimum: minPoint, maximum: maxPoint)
    }
}
