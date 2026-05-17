#if os(iOS) && canImport(ARKit)
import ARKit
import simd

enum ARMeshSnapshotConverter {
    static func snapshot(from anchor: ARMeshAnchor) -> MeshSnapshot {
        let geometry = anchor.geometry
        let vertices = (0..<geometry.vertices.count).map { index in
            let vertex: (Float, Float, Float) = geometry.vertices[Int32(index)]
            return SIMD3<Float>(vertex.0, vertex.1, vertex.2)
        }
        let faces = (0..<geometry.faces.count).compactMap { index -> SIMD3<UInt32>? in
            let face = geometry.faces[index]
            guard face.count >= 3 else {
                return nil
            }

            return SIMD3<UInt32>(
                UInt32(face[0]),
                UInt32(face[1]),
                UInt32(face[2])
            )
        }
        let classifications = (0..<faces.count).map { index in
            faceClassification(from: geometry, at: index)
        }

        return MeshSnapshot(
            anchorID: MeshAnchorID(rawValue: anchor.identifier),
            transform: anchor.transform,
            vertices: vertices,
            faces: faces,
            classifications: classifications
        )
    }

    private static func faceClassification(from geometry: ARMeshGeometry, at index: Int) -> MeshFaceClassification {
        guard let classificationSource = geometry.classification,
              classificationSource.count > index else {
            return .none
        }

        let rawValue: CUnsignedChar = classificationSource[Int32(index)]
        return MeshFaceClassification(arMeshRawValue: Int(rawValue))
    }
}
#endif
