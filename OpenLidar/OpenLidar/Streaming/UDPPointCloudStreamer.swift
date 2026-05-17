import Foundation
import Network

public actor UDPPointCloudStreamer {
    private let connection: NWConnection

    public init(host: String, port: UInt16) {
        self.connection = NWConnection(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(rawValue: port)!,
            using: .udp
        )
    }

    public func start(queue: DispatchQueue = .global(qos: .userInteractive)) {
        connection.start(queue: queue)
    }

    public func stop() {
        connection.cancel()
    }

    public func send(_ chunk: PointCloudChunk) async throws {
        let packet = try StreamPacketCodec.makePointCloudPacket(chunk)
        let data = StreamPacketCodec.encode(packet)
        try await send(data)
    }

    public func send(_ data: Data) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            connection.send(content: data, completion: .contentProcessed { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            })
        }
    }
}
