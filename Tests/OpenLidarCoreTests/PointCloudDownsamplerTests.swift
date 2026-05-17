import Testing
import OpenLidarCore

@Test func strideSampleLimitsPointCount() {
    let points = (0..<1_000).map { PointXYZRGBA(x: Float($0), y: 0, z: 0) }

    let sampled = PointCloudDownsampler.strideSample(points, limit: 100)

    #expect(sampled.count == 100)
    #expect(sampled.first?.x == 0)
}
