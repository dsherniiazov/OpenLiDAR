import Foundation

struct SavedScan: Identifiable, Equatable {
    let id: UUID
    let name: String
    let createdAt: Date
    let duration: TimeInterval
    let points: [PointXYZRGBA]
    let previewPoints: [PointXYZRGBA]
    let bounds: AxisAlignedBounds?
    let meshSnapshots: [MeshSnapshot]
    let meshBounds: AxisAlignedBounds?
    var lastExportURL: URL?
    var lastMeshExportURL: URL?

    var pointCount: Int {
        points.count
    }

    var meshFaceCount: Int {
        meshSnapshots.reduce(0) { $0 + $1.faces.count }
    }
}
