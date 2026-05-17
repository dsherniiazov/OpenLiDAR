import Foundation
import simd

enum MeshNormalGenerator {
    static func vertexNormals(vertices: [SIMD3<Float>], faces: [SIMD3<Int>]) -> [SIMD3<Float>] {
        var normals = Array(repeating: SIMD3<Float>(repeating: 0), count: vertices.count)

        for face in faces {
            guard face.x >= 0,
                  face.y >= 0,
                  face.z >= 0,
                  face.x < vertices.count,
                  face.y < vertices.count,
                  face.z < vertices.count else {
                continue
            }

            let edgeA = vertices[face.y] - vertices[face.x]
            let edgeB = vertices[face.z] - vertices[face.x]
            let faceNormal = simd_cross(edgeA, edgeB)
            guard simd_length_squared(faceNormal) > 0 else {
                continue
            }

            normals[face.x] += faceNormal
            normals[face.y] += faceNormal
            normals[face.z] += faceNormal
        }

        return normals.map { normal in
            guard simd_length_squared(normal) > 0 else {
                return SIMD3<Float>(repeating: 0)
            }

            return simd_normalize(normal)
        }
    }
}
