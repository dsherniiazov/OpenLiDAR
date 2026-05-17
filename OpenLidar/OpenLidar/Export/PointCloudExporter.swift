import Foundation

enum PointCloudExportFormat: String, CaseIterable, Identifiable {
    case plyASCII
    case xyz
    case obj
    case pts
    case csv
    case json

    var id: String { rawValue }

    var title: String {
        switch self {
        case .plyASCII:
            "PLY"
        case .xyz:
            "XYZ"
        case .obj:
            "OBJ"
        case .pts:
            "PTS"
        case .csv:
            "CSV"
        case .json:
            "JSON"
        }
    }

    var fileExtension: String {
        switch self {
        case .plyASCII:
            "ply"
        case .xyz:
            "xyz"
        case .obj:
            "obj"
        case .pts:
            "pts"
        case .csv:
            "csv"
        case .json:
            "json"
        }
    }
}

enum PointCloudExporter {
    static func data(for points: [PointXYZRGBA], format: PointCloudExportFormat) throws -> Data {
        switch format {
        case .plyASCII:
            PLYExporter.ascii(points: points)
        case .xyz:
            xyz(points: points)
        case .obj:
            obj(points: points)
        case .pts:
            pts(points: points)
        case .csv:
            csv(points: points)
        case .json:
            try json(points: points)
        }
    }

    static func write(points: [PointXYZRGBA], format: PointCloudExportFormat, to url: URL) throws {
        try data(for: points, format: format).write(to: url, options: .atomic)
    }

    private static func xyz(points: [PointXYZRGBA]) -> Data {
        var output = ""
        output.reserveCapacity(points.count * 28)

        for point in points {
            output += "\(point.x) \(point.y) \(point.z)\n"
        }

        return Data(output.utf8)
    }

    private static func csv(points: [PointXYZRGBA]) -> Data {
        var output = "x,y,z,red,green,blue,alpha,confidence\n"
        output.reserveCapacity(40 + points.count * 36)

        for point in points {
            output += "\(point.x),\(point.y),\(point.z),\(point.red),\(point.green),\(point.blue),\(point.alpha),\(point.confidence)\n"
        }

        return Data(output.utf8)
    }

    private static func obj(points: [PointXYZRGBA]) -> Data {
        var output = "# OpenLidar point cloud\n"
        output.reserveCapacity(24 + points.count * 48)

        for point in points {
            let red = Float(point.red) / 255
            let green = Float(point.green) / 255
            let blue = Float(point.blue) / 255
            output += "v \(point.x) \(point.y) \(point.z) \(red) \(green) \(blue)\n"
        }

        return Data(output.utf8)
    }

    private static func pts(points: [PointXYZRGBA]) -> Data {
        var output = "\(points.count)\n"
        output.reserveCapacity(12 + points.count * 36)

        for point in points {
            output += "\(point.x) \(point.y) \(point.z) \(point.red) \(point.green) \(point.blue)\n"
        }

        return Data(output.utf8)
    }

    private static func json(points: [PointXYZRGBA]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(points)
    }
}
