import Foundation

enum MeshExportFormat: String, CaseIterable, Identifiable {
    case plyASCII
    case obj

    var id: String { rawValue }

    var title: String {
        switch self {
        case .plyASCII:
            "PLY"
        case .obj:
            "OBJ"
        }
    }

    var fileExtension: String {
        switch self {
        case .plyASCII:
            "ply"
        case .obj:
            "obj"
        }
    }
}

enum MeshExporter {
    static func data(for snapshots: [MeshSnapshot], format: MeshExportFormat) -> Data {
        switch format {
        case .plyASCII:
            PLYExporter.asciiMesh(snapshots: snapshots)
        case .obj:
            obj(snapshots: snapshots)
        }
    }

    static func write(snapshots: [MeshSnapshot], format: MeshExportFormat, to url: URL) throws {
        try data(for: snapshots, format: format).write(to: url, options: .atomic)
    }

    private static func obj(snapshots: [MeshSnapshot]) -> Data {
        let mesh = MeshExportGeometry(snapshots: snapshots)
        var output = "# OpenLidar mesh\n"
        output.reserveCapacity(18 + mesh.vertices.count * 56 + mesh.faces.count * 24)

        for vertex in mesh.vertices {
            output += "v \(vertex.x) \(vertex.y) \(vertex.z)\n"
        }

        for normal in mesh.vertexNormals {
            output += "vn \(normal.x) \(normal.y) \(normal.z)\n"
        }

        for face in mesh.faces {
            let first = face.x + 1
            let second = face.y + 1
            let third = face.z + 1
            output += "f \(first)//\(first) \(second)//\(second) \(third)//\(third)\n"
        }

        return Data(output.utf8)
    }
}
