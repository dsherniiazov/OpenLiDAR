import simd
import Testing
import OpenLidarCore

@Test func projectsDepthPixelsIntoWorldSpace() {
    let intrinsics = CameraIntrinsics(fx: 1, fy: 1, cx: 0, cy: 0, width: 2, height: 1)

    let points = DepthPointCloudProjector.project(
        depthMeters: [1, 2],
        width: 2,
        height: 1,
        intrinsics: intrinsics,
        cameraToWorld: matrix_identity_float4x4,
        pixelStride: 1
    )

    #expect(points.count == 2)
    #expect(points[0].x == 0)
    #expect(points[0].y == 0)
    #expect(points[0].z == -1)
    #expect(points[1].x == 2)
    #expect(points[1].z == -2)
}

@Test func filtersLowConfidenceDepthPixels() {
    let intrinsics = CameraIntrinsics(fx: 1, fy: 1, cx: 0, cy: 0, width: 2, height: 1)

    let points = DepthPointCloudProjector.project(
        depthMeters: [1, 2],
        width: 2,
        height: 1,
        intrinsics: intrinsics,
        cameraToWorld: matrix_identity_float4x4,
        pixelStride: 1,
        confidence: [0, 2],
        minimumConfidence: 1
    )

    #expect(points.count == 1)
    #expect(points[0].x == 2)
}
