import Foundation

public enum StreamPacketType: UInt8, Codable, Sendable {
    case hello = 1
    case pose = 2
    case pointCloudChunk = 3
    case status = 4
}

public enum StreamProtocolError: Error, Equatable {
    case invalidMagic
    case unsupportedVersion(UInt8)
    case unknownPacketType(UInt8)
    case malformedPayload
}

public struct StreamPacket: Sendable, Equatable {
    public static let magic: UInt32 = 0x4F4C4452
    public static let version: UInt8 = 1
    public static let headerSize = 26

    public var type: StreamPacketType
    public var sequenceNumber: UInt64
    public var timestampNanoseconds: UInt64
    public var payload: Data

    public init(
        type: StreamPacketType,
        sequenceNumber: UInt64,
        timestampNanoseconds: UInt64,
        payload: Data
    ) {
        self.type = type
        self.sequenceNumber = sequenceNumber
        self.timestampNanoseconds = timestampNanoseconds
        self.payload = payload
    }
}

public enum StreamPacketCodec {
    public static func encode(_ packet: StreamPacket) -> Data {
        var data = Data(capacity: StreamPacket.headerSize + packet.payload.count)
        data.appendBigEndian(StreamPacket.magic)
        data.append(StreamPacket.version)
        data.append(packet.type.rawValue)
        data.appendBigEndian(packet.sequenceNumber)
        data.appendBigEndian(packet.timestampNanoseconds)
        data.appendBigEndian(UInt32(packet.payload.count))
        data.append(packet.payload)
        return data
    }

    public static func decode(_ data: Data) throws -> StreamPacket {
        guard data.count >= StreamPacket.headerSize else {
            throw StreamProtocolError.malformedPayload
        }

        let magic = data.readBigEndianUInt32(at: 0)
        guard magic == StreamPacket.magic else {
            throw StreamProtocolError.invalidMagic
        }

        let version = data[4]
        guard version == StreamPacket.version else {
            throw StreamProtocolError.unsupportedVersion(version)
        }

        guard let type = StreamPacketType(rawValue: data[5]) else {
            throw StreamProtocolError.unknownPacketType(data[5])
        }

        let sequence = data.readBigEndianUInt64(at: 6)
        let timestamp = data.readBigEndianUInt64(at: 14)
        let payloadSize = Int(data.readBigEndianUInt32(at: 22))
        guard data.count == StreamPacket.headerSize + payloadSize else {
            throw StreamProtocolError.malformedPayload
        }

        return StreamPacket(
            type: type,
            sequenceNumber: sequence,
            timestampNanoseconds: timestamp,
            payload: data.subdata(in: StreamPacket.headerSize..<data.count)
        )
    }
}

extension StreamPacketCodec {
    public static func makePointCloudPacket(_ chunk: PointCloudChunk) throws -> StreamPacket {
        let payload = try JSONEncoder.openLidar.encode(chunk)
        return StreamPacket(
            type: .pointCloudChunk,
            sequenceNumber: chunk.sequenceNumber,
            timestampNanoseconds: UInt64(chunk.timestamp * 1_000_000_000),
            payload: payload
        )
    }

    public static func decodePointCloudChunk(from packet: StreamPacket) throws -> PointCloudChunk {
        guard packet.type == .pointCloudChunk else {
            throw StreamProtocolError.malformedPayload
        }
        return try JSONDecoder.openLidar.decode(PointCloudChunk.self, from: packet.payload)
    }
}

private extension JSONEncoder {
    static var openLidar: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    static var openLidar: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

private extension Data {
    mutating func appendBigEndian(_ value: UInt32) {
        var bigEndian = value.bigEndian
        Swift.withUnsafeBytes(of: &bigEndian) { append(contentsOf: $0) }
    }

    mutating func appendBigEndian(_ value: UInt64) {
        var bigEndian = value.bigEndian
        Swift.withUnsafeBytes(of: &bigEndian) { append(contentsOf: $0) }
    }

    func readBigEndianUInt32(at offset: Int) -> UInt32 {
        self[offset..<(offset + 4)].reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
    }

    func readBigEndianUInt64(at offset: Int) -> UInt64 {
        self[offset..<(offset + 8)].reduce(UInt64(0)) { ($0 << 8) | UInt64($1) }
    }
}
