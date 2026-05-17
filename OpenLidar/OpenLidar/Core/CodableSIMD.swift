import simd

extension simd_float4x4: @retroactive Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let columns = try (0..<4).map { _ in
            let x = try container.decode(Float.self)
            let y = try container.decode(Float.self)
            let z = try container.decode(Float.self)
            let w = try container.decode(Float.self)
            return SIMD4<Float>(x, y, z, w)
        }
        self.init(columns[0], columns[1], columns[2], columns[3])
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        for column in [columns.0, columns.1, columns.2, columns.3] {
            try container.encode(column.x)
            try container.encode(column.y)
            try container.encode(column.z)
            try container.encode(column.w)
        }
    }
}
