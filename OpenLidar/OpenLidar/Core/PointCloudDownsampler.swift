import Foundation

public enum PointCloudDownsampler {
    public static func strideSample(_ points: [PointXYZRGBA], limit: Int) -> [PointXYZRGBA] {
        guard limit > 0, points.count > limit else {
            return points
        }

        let stride = max(1, Int(ceil(Double(points.count) / Double(limit))))
        var sampled: [PointXYZRGBA] = []
        sampled.reserveCapacity(limit)

        var index = 0
        while index < points.count && sampled.count < limit {
            sampled.append(points[index])
            index += stride
        }

        return sampled
    }
}
