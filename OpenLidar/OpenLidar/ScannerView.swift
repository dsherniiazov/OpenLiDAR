import SwiftUI
#if os(iOS) && canImport(ARKit)
import ARKit
#endif

struct ScannerView: View {
    @State private var model = ScannerViewModel()
    @State private var mode: CaptureMode?
    @State private var isShowingSettings = false

    var body: some View {
        NavigationStack {
            Group {
                if let mode {
                    captureView(for: mode)
                } else {
                    homeView
                }
            }
            .navigationTitle(mode?.title ?? "OpenLidar")
            .toolbar {
                if mode != nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            model.stop()
                            self.mode = nil
                        } label: {
                            Label("Menu", systemImage: "chevron.left")
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            isShowingSettings = true
                        } label: {
                            Label("Settings", systemImage: "gearshape")
                        }
                    }
                }
            }
            .sheet(isPresented: $isShowingSettings) {
                settingsView
            }
        }
    }

    private var homeView: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer(minLength: 20)

            VStack(alignment: .leading, spacing: 10) {
                Text("OpenLidar")
                    .font(.system(size: 42, weight: .bold))
                Text("Capture LiDAR point clouds locally, export files, or stream live data to a PC.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 14) {
                modeButton(
                    title: "Scan",
                    subtitle: "Capture and export a local point cloud",
                    systemImage: "viewfinder",
                    tint: .blue
                ) {
                    model.streamingEnabled = false
                    mode = .scan
                }
                .disabled(!captureReadiness.canStartCapture)

                modeButton(
                    title: "Stream",
                    subtitle: "Send live point cloud chunks over UDP while scanning",
                    systemImage: "dot.radiowaves.left.and.right",
                    tint: .green
                ) {
                    model.streamingEnabled = true
                    mode = .stream
                }
                .disabled(!captureReadiness.canStartCapture)
            }

            if !captureReadiness.canStartCapture {
                captureUnavailablePanel
            }

            capabilityPanel
            Spacer()
        }
        .padding()
    }

    private func captureView(for mode: CaptureMode) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if !captureReadiness.canStartCapture {
                    captureUnavailablePanel
                }

                LidarPreviewView(session: previewSession)
                    .frame(height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                PointCloudPreviewView(points: model.previewPoints, bounds: model.scanBounds)
                    .frame(height: 180)

                MeshWireframePreviewView(snapshots: model.meshSnapshots, bounds: model.meshSummary.bounds)
                    .frame(height: 180)

                primaryControls(for: mode)
                    .disabled(!captureReadiness.canStartCapture)
                metricsPanel
                exportStatus
                savedScansList
            }
            .padding()
        }
    }

    private func modeButton(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .frame(width: 42, height: 42)
                    .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(tint)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private func primaryControls(for mode: CaptureMode) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(mode == .stream ? "Live Stream" : "Scan Session")
                    .font(.headline)
                Spacer()
                Text(stateText)
                    .font(.subheadline)
                    .foregroundStyle(statusColor)
            }

            HStack(spacing: 12) {
                Button {
                    handleStartStop(mode: mode)
                } label: {
                    Label(primaryActionTitle(for: mode), systemImage: model.isScanning ? "stop.circle" : "record.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(model.isScanning ? .red : (mode == .stream ? .green : .blue))

                Button {
                    if model.isPaused {
                        model.resume()
                    } else {
                        model.pause()
                    }
                } label: {
                    Label(model.isPaused ? "Resume" : "Pause", systemImage: model.isPaused ? "play.circle" : "pause.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(!model.isScanning)
            }
        }
    }

    private var savedScansList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Saved Scans")
                    .font(.headline)
                Spacer()
                Picker("Format", selection: $model.selectedExportFormat) {
                    ForEach(PointCloudExportFormat.allCases) { format in
                        Text(format.title).tag(format)
                    }
                }
                .pickerStyle(.menu)

                Picker("Mesh", selection: $model.selectedMeshExportFormat) {
                    ForEach(MeshExportFormat.allCases) { format in
                        Text(format.title).tag(format)
                    }
                }
                .pickerStyle(.menu)
            }

            if model.savedScans.isEmpty {
                Text("Stop a scan to save it here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
            } else {
                ForEach(model.savedScans) { scan in
                    savedScanRow(scan)
                }
            }
        }
    }

    private func savedScanRow(_ scan: SavedScan) -> some View {
        HStack(spacing: 12) {
            Group {
                if scan.meshSnapshots.isEmpty {
                    PointCloudPreviewView(points: scan.previewPoints, bounds: scan.bounds)
                } else {
                    MeshWireframePreviewView(snapshots: scan.meshSnapshots, bounds: scan.meshBounds)
                }
            }
            .frame(width: 86, height: 70)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(scan.name)
                    .font(.headline)
                Text("\(scan.pointCount) points")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if scan.meshSnapshots.isEmpty == false {
                    Text("\(scan.meshFaceCount) mesh faces")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(scanDurationText(scan.duration))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                Button {
                    model.exportScan(scan)
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.bordered)
                .disabled(scan.points.isEmpty)

                Button {
                    model.exportMeshScan(scan)
                } label: {
                    Label("Export Mesh", systemImage: "cube")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.bordered)
                .disabled(scan.meshSnapshots.isEmpty)

                if let url = scan.lastExportURL {
                    ShareLink(item: url) {
                        Label("Share", systemImage: "paperplane")
                            .labelStyle(.iconOnly)
                    }
                    .font(.caption)
                }

                if let url = scan.lastMeshExportURL {
                    ShareLink(item: url) {
                        Label("Share Mesh", systemImage: "paperplane.fill")
                            .labelStyle(.iconOnly)
                    }
                    .font(.caption)
                }
            }
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private var captureUnavailablePanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(captureReadiness.title, systemImage: "exclamationmark.triangle")
                .font(.headline)
                .foregroundStyle(.orange)
            Text(captureReadiness.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
    }

    private var capabilityPanel: some View {
        let capabilities = ARCaptureAvailability.current

        return VStack(alignment: .leading, spacing: 8) {
            Text("Device")
                .font(.headline)
            Label(capabilities.supports(.worldTracking) ? "World tracking available" : "World tracking unavailable",
                  systemImage: capabilities.supports(.worldTracking) ? "checkmark.circle" : "xmark.circle")
            Label(capabilities.supports(.sceneDepth) || capabilities.supports(.smoothedSceneDepth) ? "Depth available" : "Depth unavailable",
                  systemImage: capabilities.supports(.sceneDepth) || capabilities.supports(.smoothedSceneDepth) ? "checkmark.circle" : "xmark.circle")
            Label(capabilities.supports(.lidarMeshReconstruction) ? "LiDAR mesh available" : "LiDAR mesh unavailable",
                  systemImage: capabilities.supports(.lidarMeshReconstruction) ? "checkmark.circle" : "xmark.circle")
        }
        .font(.subheadline)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private var metricsPanel: some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
            GridRow {
                Text("Duration")
                    .foregroundStyle(.secondary)
                Text(durationText)
                    .monospacedDigit()
            }
            GridRow {
                Text("Live points")
                    .foregroundStyle(.secondary)
                Text("\(model.livePointCount)")
                    .monospacedDigit()
            }
            GridRow {
                Text("Captured points")
                    .foregroundStyle(.secondary)
                Text("\(model.capturedPointCount)")
                    .monospacedDigit()
            }
            GridRow {
                Text("Bounds")
                    .foregroundStyle(.secondary)
                Text(boundsText)
                    .monospacedDigit()
            }
            GridRow {
                Text("Chunks")
                    .foregroundStyle(.secondary)
                Text("\(model.totalChunks)")
                    .monospacedDigit()
            }
            GridRow {
                Text("Mesh anchors")
                    .foregroundStyle(.secondary)
                Text("\(model.meshSummary.anchorCount)")
                    .monospacedDigit()
                    .accessibilityIdentifier("meshAnchorCount")
            }
            GridRow {
                Text("Mesh vertices")
                    .foregroundStyle(.secondary)
                Text("\(model.meshSummary.vertexCount)")
                    .monospacedDigit()
                    .accessibilityIdentifier("meshVertexCount")
            }
            GridRow {
                Text("Mesh faces")
                    .foregroundStyle(.secondary)
                Text("\(model.meshSummary.faceCount)")
                    .monospacedDigit()
                    .accessibilityIdentifier("meshFaceCount")
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private var settingsView: some View {
        NavigationStack {
            Form {
                Section("Depth Range") {
                    LabeledContent("Near") {
                        Text("\(model.minimumDepth, specifier: "%.1f") m")
                    }
                    Slider(value: $model.minimumDepth, in: 0.1...3.0, step: 0.1)

                    LabeledContent("Far") {
                        Text("\(model.maximumDepth, specifier: "%.1f") m")
                    }
                    Slider(value: $model.maximumDepth, in: 0.5...10.0, step: 0.1)
                }

                Section("Performance") {
                    Picker("Preview", selection: $model.previewPreset) {
                        ForEach(PreviewPerformancePreset.allCases) { preset in
                            Text(preset.title).tag(preset)
                        }
                    }

                    Picker("Save Quality", selection: $model.savePreset) {
                        ForEach(SaveQualityPreset.allCases) { preset in
                            Text(preset.title).tag(preset)
                        }
                    }

                    Picker("Point Color", selection: $model.pointColorMode) {
                        ForEach(PointColorMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                }

                Section("Streaming") {
                    Toggle("UDP Streaming", isOn: $model.streamingEnabled)
                    TextField("Host", text: $model.receiverHost)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Port", text: $model.receiverPort)
                        .keyboardType(.numberPad)
                }

                Section("Export") {
                    Picker("Format", selection: $model.selectedExportFormat) {
                        ForEach(PointCloudExportFormat.allCases) { format in
                            Text(format.title).tag(format)
                        }
                    }

                    Picker("Mesh Format", selection: $model.selectedMeshExportFormat) {
                        ForEach(MeshExportFormat.allCases) { format in
                            Text(format.title).tag(format)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        isShowingSettings = false
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var exportStatus: some View {
        if let url = model.lastExportURL {
            HStack {
                Text("Exported: \(url.lastPathComponent)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer()

                ShareLink(item: url) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.footnote)
                }
            }
            .padding(14)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
        }

        if let error = model.errorMessage {
            Text(error)
                .font(.footnote)
                .foregroundStyle(.red)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private var stateText: String {
        switch model.state {
        case .idle:
            "Ready"
        case .running:
            "Running"
        case .paused:
            "Paused"
        case .failed:
            "Failed"
        }
    }

    private func handleStartStop(mode: CaptureMode) {
        if model.isScanning {
            model.stop()
            return
        }

        guard captureReadiness.canStartCapture else {
            model.start(capabilities: ARCaptureAvailability.current)
            return
        }

        if mode == .stream {
            model.streamingEnabled = true
        }
        model.start()
    }

    private func primaryActionTitle(for mode: CaptureMode) -> String {
        if model.isScanning {
            return mode == .stream ? "Stop Streaming" : "Stop Scanning"
        }

        return mode == .stream ? "Start Streaming" : "Start Scanning"
    }

    private var statusColor: Color {
        switch model.state {
        case .idle:
            .secondary
        case .running:
            .green
        case .paused:
            .orange
        case .failed:
            .red
        }
    }

    private var durationText: String {
        scanDurationText(model.elapsedScanTime)
    }

    private func scanDurationText(_ duration: TimeInterval) -> String {
        let totalSeconds = max(0, Int(duration.rounded(.down)))
        let hours = totalSeconds / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return "\(hours):\(String(format: "%02d", minutes)):\(String(format: "%02d", seconds))"
        }

        return "\(minutes):\(String(format: "%02d", seconds))"
    }

    private var boundsText: String {
        guard let dimensions = model.scanBounds?.dimensions else {
            return "0.0 x 0.0 x 0.0 m"
        }

        return "\(dimensions.x.formatted(.number.precision(.fractionLength(1)))) x \(dimensions.y.formatted(.number.precision(.fractionLength(1)))) x \(dimensions.z.formatted(.number.precision(.fractionLength(1)))) m"
    }

    private var captureReadiness: CaptureReadiness {
        CaptureReadiness.lidarSpace(capabilities: ARCaptureAvailability.current)
    }

    #if os(iOS) && canImport(ARKit)
    private var previewSession: ARSession? {
        model.previewSession
    }
    #else
    private var previewSession: Any? {
        nil
    }
    #endif
}

private enum CaptureMode {
    case scan
    case stream

    var title: String {
        switch self {
        case .scan:
            "Scan"
        case .stream:
            "Stream"
        }
    }
}

#Preview {
    ScannerView()
}
