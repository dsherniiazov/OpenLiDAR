import Foundation
import OpenLidarCore
import ScanExport

let points = [
    PointXYZRGBA(x: 0, y: 0, z: 0, red: 255, green: 0, blue: 0),
    PointXYZRGBA(x: 1, y: 0, z: 0, red: 0, green: 255, blue: 0),
    PointXYZRGBA(x: 0, y: 1, z: 0, red: 0, green: 0, blue: 255)
]

let url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("sample-openlidar.ply")

try PLYExporter.writeASCII(points: points, to: url)
print("Wrote \(url.path)")

