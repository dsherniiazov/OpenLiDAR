import Foundation
import Observation
#if os(iOS) && canImport(ARKit)
import ARKit
#endif

@Observable
@MainActor
final class ScannerViewModel {
    private var configuration = ScanSessionConfiguration(
        mode: .lidarSpace,
        targetFramesPerSecond: 30,
        maxLivePointCount: 100_000,
        streamingTransport: .disabled
    )

    private var captureSession: LidarCaptureSession?
    private var latestChunk: PointCloudChunk?
    private var accumulatedPoints: [PointXYZRGBA] = []
    private var meshStore = MeshAnchorStore()
    private var delegateProxy: ScannerCaptureDelegate?
    private var streamer: UDPPointCloudStreamer?
    private var scanStartedAt: Date?
    private var scanTimerTask: Task<Void, Never>?
    private var scanCounter = 0

    var state: LidarCaptureState = .idle
    var isScanning = false
    var isPaused = false
    var elapsedScanTime: TimeInterval = 0
    var livePointCount = 0
    var capturedPointCount = 0
    var totalChunks = 0
    var scanBounds: AxisAlignedBounds?
    var meshSummary = MeshScanSummary(anchorCount: 0, vertexCount: 0, faceCount: 0, bounds: nil)
    var lastExportURL: URL?
    var errorMessage: String?
    var streamingEnabled = false
    var receiverHost = "192.168.1.10"
    var receiverPort = "7000"
    var minimumDepth: Double = 0.2
    var maximumDepth: Double = 5.0
    var previewPreset: PreviewPerformancePreset = .smooth
    var savePreset: SaveQualityPreset = .balanced
    var pointColorMode: PointColorMode = .green
    var selectedExportFormat: PointCloudExportFormat = .plyASCII
    var selectedMeshExportFormat: MeshExportFormat = .plyASCII
    var previewPoints: [PointXYZRGBA] = []
    var savedScans: [SavedScan] = []

    var meshSnapshots: [MeshSnapshot] {
        meshStore.allSnapshots
    }

    #if os(iOS) && canImport(ARKit)
    var previewSession: ARSession? {
        captureSession?.previewSession
    }
    #endif

    var canExport: Bool {
        accumulatedPoints.isEmpty == false
    }

    @discardableResult
    func start(capabilities: DeviceCapabilities = ARCaptureAvailability.current) -> Bool {
        if isScanning {
            finishCurrentScan()
            return true
        }

        let readiness = CaptureReadiness.lidarSpace(capabilities: capabilities)
        guard readiness.canStartCapture else {
            state = .failed(readiness.title)
            errorMessage = readiness.message
            return false
        }

        normalizeDepthRange()
        accumulatedPoints.removeAll(keepingCapacity: true)
        capturedPointCount = 0
        latestChunk = nil
        scanStartedAt = Date()
        elapsedScanTime = 0
        livePointCount = 0
        totalChunks = 0
        scanBounds = nil
        meshStore = MeshAnchorStore()
        meshSummary = meshStore.summary
        previewPoints = []
        lastExportURL = nil
        errorMessage = nil
        isScanning = true
        isPaused = false
        startScanTimer()
        configureStreaming()
        configuration.minimumDepth = Float(minimumDepth)
        configuration.maximumDepth = Float(maximumDepth)
        configuration.targetFramesPerSecond = previewPreset.targetFramesPerSecond
        configuration.maxLivePointCount = previewPreset.livePointBudget
        let session = LidarCaptureSession(configuration: configuration)
        let proxy = ScannerCaptureDelegate(
            onState: { [weak self] state in
                Task { @MainActor in
                    self?.handleCaptureState(state)
                }
            },
            onChunk: { [weak self] chunk in
                Task { @MainActor in
                    self?.processPointCloudChunk(chunk)
                }
            },
            onMeshEvent: { [weak self] event in
                Task { @MainActor in
                    self?.processMeshEvent(event)
                }
            }
        )

        session.delegate = proxy
        captureSession = session
        delegateProxy = proxy

        do {
            try session.start()
        } catch {
            let message = CaptureErrorMessage.from(error)
            isScanning = false
            state = .failed(message.title)
            errorMessage = message.message
            stopScanTimer()
            return false
        }

        return true
    }

    func stop() {
        finishCurrentScan()
    }

    func pause() {
        guard isScanning, !isPaused else {
            return
        }

        captureSession?.pause()
        isPaused = true
        stopScanTimer()
        state = .paused
    }

    func resume() {
        guard isScanning, isPaused else {
            return
        }

        isPaused = false
        startScanTimer()
        do {
            try captureSession?.start()
        } catch {
            let message = CaptureErrorMessage.from(error)
            state = .failed(message.title)
            errorMessage = message.message
        }
    }

    private func finishCurrentScan() {
        captureSession?.pause()
        captureSession = nil
        delegateProxy = nil
        stopScanTimer()
        Task {
            await streamer?.stop()
        }
        streamer = nil
        isPaused = false
        isScanning = false

        let completedMeshSummary = meshSummary
        let completedMeshSnapshots = meshSnapshots
        if accumulatedPoints.isEmpty == false || completedMeshSnapshots.isEmpty == false {
            scanCounter += 1
            let savedScan = SavedScan(
                id: UUID(),
                name: "Scan \(scanCounter)",
                createdAt: Date(),
                duration: elapsedScanTime,
                points: PointCloudStyler.style(accumulatedPoints, colorMode: pointColorMode),
                previewPoints: previewPoints,
                bounds: scanBounds,
                meshSnapshots: completedMeshSnapshots,
                meshBounds: completedMeshSummary.bounds,
                lastExportURL: nil,
                lastMeshExportURL: nil
            )
            savedScans.insert(savedScan, at: 0)
        }
    }

    func exportScan(_ scan: SavedScan) {
        guard let index = savedScans.firstIndex(where: { $0.id == scan.id }) else {
            return
        }

        do {
            let directory = try exportDirectory()
            let fileName = "openlidar-session-\(Int(Date().timeIntervalSince1970)).\(selectedExportFormat.fileExtension)"
            let url = directory.appendingPathComponent(fileName)
            try PointCloudExporter.write(points: savedScans[index].points, format: selectedExportFormat, to: url)
            savedScans[index].lastExportURL = url
            lastExportURL = url
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func exportMeshScan(_ scan: SavedScan) {
        guard let index = savedScans.firstIndex(where: { $0.id == scan.id }),
              savedScans[index].meshSnapshots.isEmpty == false else {
            return
        }

        do {
            let directory = try exportDirectory()
            let fileName = "openlidar-mesh-session-\(Int(Date().timeIntervalSince1970)).\(selectedMeshExportFormat.fileExtension)"
            let url = directory.appendingPathComponent(fileName)
            try MeshExporter.write(
                snapshots: savedScans[index].meshSnapshots,
                format: selectedMeshExportFormat,
                to: url
            )
            savedScans[index].lastMeshExportURL = url
            lastExportURL = url
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func exportDirectory() throws -> URL {
        let documents = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = documents.appendingPathComponent("OpenLidar Exports", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func configureStreaming() {
        guard streamingEnabled,
              let port = UInt16(receiverPort.trimmingCharacters(in: .whitespacesAndNewlines)),
              receiverHost.isEmpty == false else {
            streamer = nil
            configuration.streamingTransport = .disabled
            return
        }

        configuration.streamingTransport = .udpBinary
        configuration.receiverHost = receiverHost
        configuration.receiverPort = port

        let udpStreamer = UDPPointCloudStreamer(host: receiverHost, port: port)
        streamer = udpStreamer
        Task {
            await udpStreamer.start()
        }
    }

    private func streamLatestChunk(_ chunk: PointCloudChunk) async {
        guard let streamer else {
            return
        }

        do {
            try await streamer.send(chunk)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func processPointCloudChunkForTesting(_ chunk: PointCloudChunk) {
        processPointCloudChunk(chunk)
    }

    func processMeshEventForTesting(_ event: MeshAnchorEvent) {
        processMeshEvent(event)
    }

    func finishCurrentScanForTesting() {
        finishCurrentScan()
    }

    private func processPointCloudChunk(_ chunk: PointCloudChunk) {
        latestChunk = chunk
        livePointCount = chunk.points.count
        totalChunks += 1
        appendAccumulatedPoints(chunk.points)
        updatePreviewPointsFromAccumulatedScan()
        Task {
            await streamLatestChunk(chunk)
        }
    }

    private func processMeshEvent(_ event: MeshAnchorEvent) {
        meshSummary = meshStore.apply(event)
    }

    func handleCaptureStateForTesting(_ state: LidarCaptureState) {
        handleCaptureState(state)
    }

    private func handleCaptureState(_ newState: LidarCaptureState) {
        state = newState

        guard case .failed(let reason) = newState else {
            return
        }

        let message = CaptureErrorMessage.fromRawReason(reason)
        state = .failed(message.title)
        errorMessage = message.message
    }

    private func appendAccumulatedPoints(_ points: [PointXYZRGBA]) {
        guard points.isEmpty == false else {
            return
        }

        accumulatedPoints.append(contentsOf: points)
        if accumulatedPoints.count > savePreset.accumulatedPointLimit {
            accumulatedPoints = PointCloudDownsampler.strideSample(accumulatedPoints, limit: savePreset.compactionTarget)
        }
        capturedPointCount = accumulatedPoints.count
        scanBounds = AxisAlignedBounds.enclosing(accumulatedPoints)
    }

    private func updatePreviewPointsFromAccumulatedScan() {
        let sampled = PointCloudDownsampler.strideSample(accumulatedPoints, limit: previewPreset.previewPointBudget)
        previewPoints = PointCloudStyler.style(sampled, colorMode: pointColorMode)
    }

    private func normalizeDepthRange() {
        minimumDepth = min(max(minimumDepth, 0.1), 9.9)
        maximumDepth = min(max(maximumDepth, 0.2), 10.0)
        if minimumDepth >= maximumDepth {
            maximumDepth = min(10.0, minimumDepth + 0.1)
        }
    }

    private func startScanTimer() {
        scanTimerTask?.cancel()
        scanTimerTask = Task { [weak self] in
            while Task.isCancelled == false {
                await MainActor.run {
                    guard let self, let scanStartedAt = self.scanStartedAt else {
                        return
                    }
                    self.elapsedScanTime = Date().timeIntervalSince(scanStartedAt)
                }

                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    private func stopScanTimer() {
        scanTimerTask?.cancel()
        scanTimerTask = nil
        if let scanStartedAt {
            elapsedScanTime = Date().timeIntervalSince(scanStartedAt)
        }
    }
}

private final class ScannerCaptureDelegate: LidarCaptureSessionDelegate {
    private let onState: (LidarCaptureState) -> Void
    private let onChunk: (PointCloudChunk) -> Void
    private let onMeshEvent: (MeshAnchorEvent) -> Void

    init(
        onState: @escaping (LidarCaptureState) -> Void,
        onChunk: @escaping (PointCloudChunk) -> Void,
        onMeshEvent: @escaping (MeshAnchorEvent) -> Void
    ) {
        self.onState = onState
        self.onChunk = onChunk
        self.onMeshEvent = onMeshEvent
    }

    func lidarCaptureSession(_ session: LidarCaptureSession, didChangeState state: LidarCaptureState) {
        onState(state)
    }

    func lidarCaptureSession(_ session: LidarCaptureSession, didProducePointCloud chunk: PointCloudChunk) {
        onChunk(chunk)
    }

    func lidarCaptureSession(_ session: LidarCaptureSession, didProduceMeshEvent event: MeshAnchorEvent) {
        onMeshEvent(event)
    }
}
