import Foundation
import simd

struct MeshExportGeometry: Equatable {
    var vertices: [SIMD3<Float>]
    var faces: [SIMD3<Int>]
    var vertexNormals: [SIMD3<Float>]

    init(snapshots: [MeshSnapshot]) {
        var vertices: [SIMD3<Float>] = []
        var faces: [SIMD3<Int>] = []
        let orderedSnapshots = snapshots.sorted { $0.anchorID.rawValue.uuidString < $1.anchorID.rawValue.uuidString }

        for snapshot in orderedSnapshots {
            let vertexOffset = vertices.count
            vertices.append(contentsOf: snapshot.vertices.map { Self.worldVertex($0, transform: snapshot.transform) })

            for face in snapshot.faces {
                let indices = SIMD3<Int>(Int(face.x), Int(face.y), Int(face.z))
                guard indices.x < snapshot.vertices.count,
                      indices.y < snapshot.vertices.count,
                      indices.z < snapshot.vertices.count else {
                    continue
                }

                faces.append(
                    SIMD3<Int>(
                        vertexOffset + indices.x,
                        vertexOffset + indices.y,
                        vertexOffset + indices.z
                    )
                )
            }
        }

        self.vertices = vertices
        self.faces = faces
        self.vertexNormals = MeshNormalGenerator.vertexNormals(vertices: vertices, faces: faces)
    }

    private static func worldVertex(_ vertex: SIMD3<Float>, transform: simd_float4x4) -> SIMD3<Float> {
        let world = transform * SIMD4<Float>(vertex.x, vertex.y, vertex.z, 1)
        return SIMD3<Float>(world.x, world.y, world.z)
    }
}
