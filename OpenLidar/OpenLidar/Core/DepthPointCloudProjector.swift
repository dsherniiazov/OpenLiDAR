import Foundation
import simd

public enum DepthPointCloudProjector {
    public static func project(
        depthMeters: [Float],
        width: Int,
        height: Int,
        intrinsics: CameraIntrinsics,
        cameraToWorld: simd_float4x4,
        pixelStride: Int = 4,
        confidence: [UInt8]? = nil,
        minimumConfidence: UInt8 = 1,
        minimumDepth: Float = 0,
        maximumDepth: Float = .infinity
    ) -> [PointXYZRGBA] {
        guard width > 0, height > 0, depthMeters.count >= width * height else {
            return []
        }

        let step = max(1, pixelStride)
        let capacity = max(1, (width / step) * (height / step))
        var points: [PointXYZRGBA] = []
        points.reserveCapacity(capacity)

        let fx = intrinsics.fx
        let fy = intrinsics.fy
        let cx = intrinsics.cx
        let cy = intrinsics.cy

        for y in stride(from: 0, to: height, by: step) {
            for x in stride(from: 0, to: width, by: step) {
                let index = y * width + x
                let depth = depthMeters[index]

                guard depth.isFinite, depth > 0, depth >= minimumDepth, depth <= maximumDepth else {
                    continue
                }

                let pointConfidence = confidence?[safe: index] ?? 255
                guard pointConfidence >= minimumConfidence else {
                    continue
                }

                let cameraX = (Float(x) - cx) * depth / fx
                let cameraY = -(Float(y) - cy) * depth / fy
                let cameraZ = -depth
                let world = cameraToWorld * SIMD4<Float>(cameraX, cameraY, cameraZ, 1)

                points.append(PointXYZRGBA(
                    x: world.x,
                    y: world.y,
                    z: world.z,
                    confidence: pointConfidence
                ))
            }
        }

        return points
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#if canImport(CoreVideo)
import CoreVideo

public extension DepthPointCloudProjector {
    static func copyFloat32DepthMap(_ pixelBuffer: CVPixelBuffer) -> (values: [Float], width: Int, height: Int)? {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            return nil
        }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        var values: [Float] = []
        values.reserveCapacity(width * height)

        for row in 0..<height {
            let rowPointer = baseAddress.advanced(by: row * bytesPerRow)
                .assumingMemoryBound(to: Float32.self)
            for column in 0..<width {
                values.append(rowPointer[column])
            }
        }

        return (values, width, height)
    }

    static func copyUInt8Map(_ pixelBuffer: CVPixelBuffer) -> [UInt8]? {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            return nil
        }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        var values: [UInt8] = []
        values.reserveCapacity(width * height)

        for row in 0..<height {
            let rowPointer = baseAddress.advanced(by: row * bytesPerRow)
                .assumingMemoryBound(to: UInt8.self)
            for column in 0..<width {
                values.append(rowPointer[column])
            }
        }

        return values
    }
}
#endif
