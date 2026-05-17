import Foundation
import Testing
import OpenLidarCore
import ScanStreaming

@Test func pointCloudPacketRoundTrips() throws {
    let chunk = PointCloudChunk(
        scanID: ScanID(),
        sequenceNumber: 42,
        timestamp: 123.5,
        points: [PointXYZRGBA(x: 1, y: 2, z: 3, red: 10, green: 20, blue: 30)]
    )

    let packet = try StreamPacketCodec.makePointCloudPacket(chunk)
    let wireData = StreamPacketCodec.encode(packet)
    let decodedPacket = try StreamPacketCodec.decode(wireData)
    let decodedChunk = try StreamPacketCodec.decodePointCloudChunk(from: decodedPacket)

    #expect(decodedPacket.type == .pointCloudChunk)
    #expect(decodedPacket.sequenceNumber == 42)
    #expect(decodedChunk == chunk)
}

