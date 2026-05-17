import Foundation

enum PointColorMode: String, CaseIterable, Identifiable {
    case original
    case white
    case green
    case confidence
    case height

    var id: String { rawValue }

    var title: String {
        switch self {
        case .original:
            "Original"
        case .white:
            "White"
        case .green:
            "Green"
        case .confidence:
            "Confidence"
        case .height:
            "Height"
        }
    }
}

enum PointCloudStyler {
    static func style(_ points: [PointXYZRGBA], colorMode: PointColorMode) -> [PointXYZRGBA] {
        switch colorMode {
        case .original:
            return points
        case .white:
            return points.map { point in
                var point = point
                point.red = 255
                point.green = 255
                point.blue = 255
                point.alpha = 255
                return point
            }
        case .green:
            return points.map { point in
                var point = point
                point.red = 30
                point.green = 255
                point.blue = 90
                point.alpha = 255
                return point
            }
        case .confidence:
            return points.map { point in
                var point = point
                point.red = point.confidence
                point.green = point.confidence
                point.blue = point.confidence
                point.alpha = 255
                return point
            }
        case .height:
            guard let bounds = AxisAlignedBounds.enclosing(points), bounds.dimensions.y > 0 else {
                return points
            }

            return points.map { point in
                var point = point
                let t = max(0, min(1, (point.y - bounds.minimum.y) / bounds.dimensions.y))
                point.red = UInt8(t * 255)
                point.green = UInt8((1 - abs(t - 0.5) * 2) * 220)
                point.blue = UInt8((1 - t) * 255)
                point.alpha = 255
                return point
            }
        }
    }
}
