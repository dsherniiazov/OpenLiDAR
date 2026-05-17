import Foundation
import OpenLidarCore

public enum PLYExporter {
    public static func ascii(points: [PointXYZRGBA]) -> Data {
        var output = """
        ply
        format ascii 1.0
        element vertex \(points.count)
        property float x
        property float y
        property float z
        property uchar red
        property uchar green
        property uchar blue
        property uchar alpha
        property uchar confidence
        end_header

        """

        for point in points {
            output += "\(point.x) \(point.y) \(point.z) \(point.red) \(point.green) \(point.blue) \(point.alpha) \(point.confidence)\n"
        }

        return Data(output.utf8)
    }

    public static func writeASCII(points: [PointXYZRGBA], to url: URL) throws {
        try ascii(points: points).write(to: url, options: .atomic)
    }
}

