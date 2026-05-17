import Foundation
import simd

struct MeshAnchorID: Hashable, Codable, Sendable, RawRepresentable {
    let rawValue: UUID

    init(rawValue: UUID) {
        self.rawValue = rawValue
    }

    init() {
        self.rawValue = UUID()
    }
}

struct MeshSnapshot: Codable, Sendable, Equatable {
    var anchorID: MeshAnchorID
    var transform: simd_float4x4
    var vertices: [SIMD3<Float>]
    var faces: [SIMD3<UInt32>]
    var classifications: [MeshFaceClassification]

    init(
        anchorID: MeshAnchorID,
        transform: simd_float4x4,
        vertices: [SIMD3<Float>],
        faces: [SIMD3<UInt32>],
        classifications: [MeshFaceClassification] = []
    ) {
        self.anchorID = anchorID
        self.transform = transform
        self.vertices = vertices
        self.faces = faces
        self.classifications = Self.normalizedClassifications(classifications, faceCount: faces.count)
    }

    private static func normalizedClassifications(
        _ classifications: [MeshFaceClassification],
        faceCount: Int
    ) -> [MeshFaceClassification] {
        if classifications.count == faceCount {
            return classifications
        }

        if classifications.count > faceCount {
            return Array(classifications.prefix(faceCount))
        }

        return classifications + Array(repeating: .none, count: faceCount - classifications.count)
    }
}

enum MeshFaceClassification: String, Codable, Sendable, Equatable {
    case none
    case wall
    case floor
    case ceiling
    case table
    case seat
    case window
    case door
    case unknown

    init(arMeshRawValue: Int) {
        switch arMeshRawValue {
        case 0:
            self = .none
        case 1:
            self = .wall
        case 2:
            self = .floor
        case 3:
            self = .ceiling
        case 4:
            self = .table
        case 5:
            self = .seat
        case 6:
            self = .window
        case 7:
            self = .door
        default:
            self = .unknown
        }
    }
}

enum MeshAnchorEvent: Equatable {
    case added(MeshSnapshot)
    case updated(MeshSnapshot)
    case removed(MeshAnchorID)
}

struct MeshScanSummary: Equatable {
    var anchorCount: Int
    var vertexCount: Int
    var faceCount: Int
    var bounds: AxisAlignedBounds?
}

struct MeshLineSegment: Equatable {
    var start: SIMD3<Float>
    var end: SIMD3<Float>
}

enum MeshWireframeBuilder {
    static func lineSegments(from snapshots: [MeshSnapshot]) -> [MeshLineSegment] {
        snapshots.flatMap { snapshot in
            snapshot.faces.flatMap { face in
                let indices = [Int(face.x), Int(face.y), Int(face.z)]
                guard indices.allSatisfy({ $0 >= 0 && $0 < snapshot.vertices.count }) else {
                    return [MeshLineSegment]()
                }

                let vertices = indices.map { worldVertex(snapshot.vertices[$0], transform: snapshot.transform) }
                return [
                    MeshLineSegment(start: vertices[0], end: vertices[1]),
                    MeshLineSegment(start: vertices[1], end: vertices[2]),
                    MeshLineSegment(start: vertices[2], end: vertices[0])
                ]
            }
        }
    }

    private static func worldVertex(_ vertex: SIMD3<Float>, transform: simd_float4x4) -> SIMD3<Float> {
        let world = transform * SIMD4<Float>(vertex.x, vertex.y, vertex.z, 1)
        return SIMD3<Float>(world.x, world.y, world.z)
    }
}

struct MeshAnchorStore {
    private var snapshots: [MeshAnchorID: MeshSnapshot] = [:]

    var anchorCount: Int {
        snapshots.count
    }

    var allSnapshots: [MeshSnapshot] {
        snapshots.values.sorted { $0.anchorID.rawValue.uuidString < $1.anchorID.rawValue.uuidString }
    }

    subscript(anchorID: MeshAnchorID) -> MeshSnapshot? {
        snapshots[anchorID]
    }

    @discardableResult
    mutating func apply(_ event: MeshAnchorEvent) -> MeshScanSummary {
        switch event {
        case .added(let snapshot), .updated(let snapshot):
            snapshots[snapshot.anchorID] = snapshot
        case .removed(let anchorID):
            snapshots.removeValue(forKey: anchorID)
        }

        return summary
    }

    var summary: MeshScanSummary {
        let vertexCount = snapshots.values.reduce(0) { $0 + $1.vertices.count }
        let faceCount = snapshots.values.reduce(0) { $0 + $1.faces.count }
        let allPoints = snapshots.values.flatMap { snapshot in
            snapshot.vertices.map { vertex in
                let world = snapshot.transform * SIMD4<Float>(vertex.x, vertex.y, vertex.z, 1)
                return PointXYZRGBA(x: world.x, y: world.y, z: world.z)
            }
        }

        return MeshScanSummary(
            anchorCount: snapshots.count,
            vertexCount: vertexCount,
            faceCount: faceCount,
            bounds: AxisAlignedBounds.enclosing(allPoints)
        )
    }
}
