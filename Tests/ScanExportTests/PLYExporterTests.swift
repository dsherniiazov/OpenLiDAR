import Foundation
import Testing
import OpenLidarCore
import ScanExport

@Test func asciiPLYContainsHeaderAndVertices() throws {
    let data = PLYExporter.ascii(points: [
        PointXYZRGBA(x: 1, y: 2, z: 3, red: 4, green: 5, blue: 6, alpha: 7, confidence: 8)
    ])

    let text = String(decoding: data, as: UTF8.self)

    #expect(text.contains("element vertex 1"))
    #expect(text.contains("property uchar confidence"))
    #expect(text.contains("1.0 2.0 3.0 4 5 6 7 8"))
}
