//
//  OpenLidarTests.swift
//  OpenLidarTests
//
//  Created by Daniiar on 15.05.2026.
//

import Testing
import Foundation
import simd
@testable import OpenLidar

struct OpenLidarTests {

    @Test func downsamplerLimitsPointCount() async throws {
        let points = [
            PointXYZRGBA(x: 0, y: 0, z: 0),
            PointXYZRGBA(x: 1, y: 0, z: 0)
        ]

        let sampled = PointCloudDownsampler.strideSample(points, limit: 1)
        #expect(sampled.count == 1)
    }

    @Test func downsamplerSamplesAcrossWholePointSet() {
        let points = (0..<5).map { PointXYZRGBA(x: Float($0), y: 0, z: 0) }

        let sampled = PointCloudDownsampler.strideSample(points, limit: 3)

        #expect(sampled.map(\.x) == [0, 2, 4])
    }

    @Test func projectorKeepsDepthSamplesWithinClipRange() {
        let intrinsics = CameraIntrinsics(fx: 1, fy: 1, cx: 0, cy: 0, width: 3, height: 1)

        let points = DepthPointCloudProjector.project(
            depthMeters: [0.25, 1.0, 3.0],
            width: 3,
            height: 1,
            intrinsics: intrinsics,
            cameraToWorld: matrix_identity_float4x4,
            pixelStride: 1,
            minimumDepth: 0.5,
            maximumDepth: 2.0
        )

        #expect(points.count == 1)
        #expect(points[0].x == 1)
        #expect(points[0].z == -1)
    }

    @Test func projectorKeepsDepthSamplesOnClipBoundaries() {
        let intrinsics = CameraIntrinsics(fx: 1, fy: 1, cx: 0, cy: 0, width: 2, height: 1)

        let points = DepthPointCloudProjector.project(
            depthMeters: [0.5, 2.0],
            width: 2,
            height: 1,
            intrinsics: intrinsics,
            cameraToWorld: matrix_identity_float4x4,
            pixelStride: 1,
            minimumDepth: 0.5,
            maximumDepth: 2.0
        )

        #expect(points.count == 2)
        #expect(points[0].z == -0.5)
        #expect(points[1].z == -2.0)
    }

    @Test func boundsReportsDimensions() {
        let bounds = AxisAlignedBounds(
            minimum: SIMD3<Float>(-1, 2, -3),
            maximum: SIMD3<Float>(4, 6, 5)
        )

        #expect(bounds.dimensions == SIMD3<Float>(5, 4, 8))
    }

    @MainActor
    @Test func scannerViewModelUpdatesBoundsWhenChunkArrives() {
        let model = ScannerViewModel()
        let chunk = PointCloudChunk(
            scanID: ScanID(),
            sequenceNumber: 1,
            timestamp: 0,
            points: [
                PointXYZRGBA(x: -1, y: 0, z: 2),
                PointXYZRGBA(x: 3, y: 5, z: -4)
            ]
        )

        model.processPointCloudChunkForTesting(chunk)

        #expect(model.scanBounds?.minimum == SIMD3<Float>(-1, 0, -4))
        #expect(model.scanBounds?.maximum == SIMD3<Float>(3, 5, 2))
        #expect(model.scanBounds?.dimensions == SIMD3<Float>(4, 5, 6))
    }

    @MainActor
    @Test func scannerPreviewUsesAccumulatedScanAcrossChunks() {
        let model = ScannerViewModel()
        let scanID = ScanID()
        let firstChunk = PointCloudChunk(
            scanID: scanID,
            sequenceNumber: 1,
            timestamp: 0,
            points: [PointXYZRGBA(x: -10, y: 0, z: 0)]
        )
        let secondChunk = PointCloudChunk(
            scanID: scanID,
            sequenceNumber: 2,
            timestamp: 1,
            points: [PointXYZRGBA(x: 10, y: 0, z: 0)]
        )

        model.processPointCloudChunkForTesting(firstChunk)
        model.processPointCloudChunkForTesting(secondChunk)

        #expect(model.previewPoints.map(\.x) == [-10, 10])
        #expect(model.scanBounds?.minimum.x == -10)
        #expect(model.scanBounds?.maximum.x == 10)
    }

    @MainActor
    @Test func savedScanPreviewUsesAccumulatedScanAcrossChunks() {
        let model = ScannerViewModel()
        let scanID = ScanID()

        model.processPointCloudChunkForTesting(
            PointCloudChunk(
                scanID: scanID,
                sequenceNumber: 1,
                timestamp: 0,
                points: [PointXYZRGBA(x: -5, y: 0, z: 0)]
            )
        )
        model.processPointCloudChunkForTesting(
            PointCloudChunk(
                scanID: scanID,
                sequenceNumber: 2,
                timestamp: 1,
                points: [PointXYZRGBA(x: 5, y: 0, z: 0)]
            )
        )
        model.finishCurrentScanForTesting()

        #expect(model.savedScans.count == 1)
        #expect(model.savedScans[0].previewPoints.map(\.x) == [-5, 5])
        #expect(model.savedScans[0].pointCount == 2)
    }


    @Test func pointCloudExporterWritesXYZ() throws {
        let points = [
            PointXYZRGBA(x: 1, y: 2, z: 3),
            PointXYZRGBA(x: -1, y: -2, z: -3)
        ]

        let data = try PointCloudExporter.data(for: points, format: .xyz)
        let text = String(decoding: data, as: UTF8.self)

        #expect(PointCloudExportFormat.xyz.fileExtension == "xyz")
        #expect(text == "1.0 2.0 3.0\n-1.0 -2.0 -3.0\n")
    }

    @Test func pointCloudExporterWritesCSVWithColorAndConfidence() throws {
        let points = [
            PointXYZRGBA(x: 1, y: 2, z: 3, red: 4, green: 5, blue: 6, alpha: 7, confidence: 8)
        ]

        let data = try PointCloudExporter.data(for: points, format: .csv)
        let text = String(decoding: data, as: UTF8.self)

        #expect(PointCloudExportFormat.csv.fileExtension == "csv")
        #expect(text == "x,y,z,red,green,blue,alpha,confidence\n1.0,2.0,3.0,4,5,6,7,8\n")
    }

    @Test func pointCloudExporterWritesJSONPoints() throws {
        let points = [
            PointXYZRGBA(x: 1, y: 2, z: 3, confidence: 9)
        ]

        let data = try PointCloudExporter.data(for: points, format: .json)
        let decoded = try JSONDecoder().decode([PointXYZRGBA].self, from: data)

        #expect(PointCloudExportFormat.json.fileExtension == "json")
        #expect(decoded == points)
    }

    @Test func pointCloudExporterWritesOBJVertices() throws {
        let points = [
            PointXYZRGBA(x: 1, y: 2, z: 3, red: 4, green: 5, blue: 6)
        ]

        let data = try PointCloudExporter.data(for: points, format: .obj)
        let text = String(decoding: data, as: UTF8.self)

        #expect(PointCloudExportFormat.obj.fileExtension == "obj")
        #expect(text == "# OpenLidar point cloud\nv 1.0 2.0 3.0 0.015686275 0.019607844 0.023529412\n")
    }

    @Test func pointCloudExporterWritesPTS() throws {
        let points = [
            PointXYZRGBA(x: 1, y: 2, z: 3, red: 4, green: 5, blue: 6)
        ]

        let data = try PointCloudExporter.data(for: points, format: .pts)
        let text = String(decoding: data, as: UTF8.self)

        #expect(PointCloudExportFormat.pts.fileExtension == "pts")
        #expect(text == "1\n1.0 2.0 3.0 4 5 6\n")
    }

    @Test func plyExporterWritesMeshVerticesAndFacesInWorldSpace() {
        var transform = matrix_identity_float4x4
        transform.columns.3 = SIMD4<Float>(10, 0, -5, 1)
        let snapshot = MeshSnapshot(
            anchorID: MeshAnchorID(rawValue: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!),
            transform: transform,
            vertices: [
                SIMD3<Float>(0, 0, 0),
                SIMD3<Float>(1, 0, 0),
                SIMD3<Float>(0, 1, 0)
            ],
            faces: [SIMD3<UInt32>(0, 1, 2)]
        )

        let text = String(decoding: PLYExporter.asciiMesh(snapshots: [snapshot]), as: UTF8.self)

        #expect(text == """
        ply
        format ascii 1.0
        element vertex 3
        property float x
        property float y
        property float z
        element face 1
        property list uchar int vertex_indices
        end_header
        10.0 0.0 -5.0
        11.0 0.0 -5.0
        10.0 1.0 -5.0
        3 0 1 2

        """)
    }

    @Test func plyExporterOffsetsFacesAcrossMeshAnchors() {
        let first = MeshSnapshot(
            anchorID: MeshAnchorID(rawValue: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!),
            transform: matrix_identity_float4x4,
            vertices: [
                SIMD3<Float>(0, 0, 0),
                SIMD3<Float>(1, 0, 0),
                SIMD3<Float>(0, 1, 0)
            ],
            faces: [SIMD3<UInt32>(0, 1, 2)]
        )
        let second = MeshSnapshot(
            anchorID: MeshAnchorID(rawValue: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!),
            transform: matrix_identity_float4x4,
            vertices: [
                SIMD3<Float>(2, 0, 0),
                SIMD3<Float>(3, 0, 0),
                SIMD3<Float>(2, 1, 0)
            ],
            faces: [SIMD3<UInt32>(0, 1, 2)]
        )

        let text = String(decoding: PLYExporter.asciiMesh(snapshots: [second, first]), as: UTF8.self)

        #expect(text.contains("element vertex 6"))
        #expect(text.contains("element face 2"))
        #expect(text.contains("3 0 1 2\n3 3 4 5\n"))
    }

    @Test func meshExporterWritesOBJFacesWithOneBasedIndicesAndNormals() {
        var transform = matrix_identity_float4x4
        transform.columns.3 = SIMD4<Float>(10, 0, -5, 1)
        let snapshot = MeshSnapshot(
            anchorID: MeshAnchorID(rawValue: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!),
            transform: transform,
            vertices: [
                SIMD3<Float>(0, 0, 0),
                SIMD3<Float>(1, 0, 0),
                SIMD3<Float>(0, 1, 0)
            ],
            faces: [SIMD3<UInt32>(0, 1, 2)]
        )

        let data = MeshExporter.data(for: [snapshot], format: .obj)
        let text = String(decoding: data, as: UTF8.self)

        #expect(MeshExportFormat.obj.fileExtension == "obj")
        #expect(text == """
        # OpenLidar mesh
        v 10.0 0.0 -5.0
        v 11.0 0.0 -5.0
        v 10.0 1.0 -5.0
        vn 0.0 0.0 1.0
        vn 0.0 0.0 1.0
        vn 0.0 0.0 1.0
        f 1//1 2//2 3//3

        """)
    }

    @Test func meshNormalGeneratorComputesVertexNormals() {
        let vertices = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(1, 0, 0),
            SIMD3<Float>(0, 1, 0)
        ]
        let faces = [SIMD3<Int>(0, 1, 2)]

        let normals = MeshNormalGenerator.vertexNormals(vertices: vertices, faces: faces)

        #expect(normals == [
            SIMD3<Float>(0, 0, 1),
            SIMD3<Float>(0, 0, 1),
            SIMD3<Float>(0, 0, 1)
        ])
    }

    @Test func meshNormalGeneratorSkipsDegenerateFaces() {
        let vertices = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(1, 0, 0),
            SIMD3<Float>(2, 0, 0)
        ]
        let faces = [SIMD3<Int>(0, 1, 2)]

        let normals = MeshNormalGenerator.vertexNormals(vertices: vertices, faces: faces)

        #expect(normals == [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(0, 0, 0)
        ])
    }

    @Test func pointCloudStylerAppliesGreenColor() {
        let points = [
            PointXYZRGBA(x: 1, y: 2, z: 3, red: 1, green: 2, blue: 3)
        ]

        let styled = PointCloudStyler.style(points, colorMode: .green)

        #expect(styled[0].red == 30)
        #expect(styled[0].green == 255)
        #expect(styled[0].blue == 90)
    }

    @MainActor
    @Test func stoppingScanStoresSavedScan() {
        let model = ScannerViewModel()
        let chunk = PointCloudChunk(
            scanID: ScanID(),
            sequenceNumber: 1,
            timestamp: 0,
            points: [
                PointXYZRGBA(x: 0, y: 0, z: 0),
                PointXYZRGBA(x: 1, y: 1, z: 1)
            ]
        )

        model.processPointCloudChunkForTesting(chunk)
        model.finishCurrentScanForTesting()

        #expect(model.savedScans.count == 1)
        #expect(model.savedScans[0].pointCount == 2)
        #expect(model.savedScans[0].previewPoints.isEmpty == false)
    }

    @MainActor
    @Test func stoppingScanStoresAccumulatedMeshSnapshots() {
        let model = ScannerViewModel()
        let snapshot = MeshSnapshot(
            anchorID: MeshAnchorID(),
            transform: matrix_identity_float4x4,
            vertices: [
                SIMD3<Float>(0, 0, 0),
                SIMD3<Float>(1, 0, 0),
                SIMD3<Float>(0, 1, 0)
            ],
            faces: [SIMD3<UInt32>(0, 1, 2)]
        )

        model.processMeshEventForTesting(.added(snapshot))
        model.finishCurrentScanForTesting()

        #expect(model.savedScans.count == 1)
        #expect(model.savedScans[0].meshSnapshots == [snapshot])
        #expect(model.savedScans[0].meshFaceCount == 1)
    }

    @MainActor
    @Test func scannerViewModelExportsSelectedMeshFormat() {
        let model = ScannerViewModel()
        let snapshot = MeshSnapshot(
            anchorID: MeshAnchorID(),
            transform: matrix_identity_float4x4,
            vertices: [
                SIMD3<Float>(0, 0, 0),
                SIMD3<Float>(1, 0, 0),
                SIMD3<Float>(0, 1, 0)
            ],
            faces: [SIMD3<UInt32>(0, 1, 2)]
        )

        model.processMeshEventForTesting(.added(snapshot))
        model.finishCurrentScanForTesting()
        model.selectedMeshExportFormat = .obj
        model.exportMeshScan(model.savedScans[0])

        #expect(model.savedScans[0].lastMeshExportURL?.pathExtension == "obj")
        #expect(model.lastExportURL?.pathExtension == "obj")
    }

    @MainActor
    @Test func pauseAndResumeAreNoOpsWhenIdle() {
        let model = ScannerViewModel()

        model.pause()
        #expect(!model.isPaused)
        #expect(model.savedScans.isEmpty)

        model.resume()
        #expect(!model.isPaused)
        #expect(model.savedScans.isEmpty)
    }

    @Test func lidarReadinessAcceptsWorldTrackingAndDepth() {
        let readiness = CaptureReadiness.lidarSpace(
            capabilities: DeviceCapabilities(supported: [.worldTracking, .sceneDepth])
        )

        #expect(readiness.canStartCapture)
        #expect(readiness.missingCapabilities.isEmpty)
    }

    @Test func lidarReadinessRejectsDeviceWithoutDepth() {
        let readiness = CaptureReadiness.lidarSpace(
            capabilities: DeviceCapabilities(supported: [.worldTracking])
        )

        #expect(!readiness.canStartCapture)
        #expect(readiness.title == "LiDAR depth unavailable")
        #expect(readiness.missingCapabilities == [.sceneDepth])
    }

    @Test func lidarReadinessRejectsDeviceWithoutWorldTracking() {
        let readiness = CaptureReadiness.lidarSpace(
            capabilities: DeviceCapabilities(supported: [.sceneDepth])
        )

        #expect(!readiness.canStartCapture)
        #expect(readiness.title == "AR tracking unavailable")
        #expect(readiness.missingCapabilities == [.worldTracking])
    }

    @MainActor
    @Test func scannerViewModelDoesNotStartWhenLidarDepthIsUnavailable() {
        let model = ScannerViewModel()
        let didStart = model.start(
            capabilities: DeviceCapabilities(supported: [.worldTracking])
        )

        #expect(!didStart)
        #expect(!model.isScanning)
        #expect(model.errorMessage == "OpenLidar needs scene depth from a LiDAR-capable iPhone or iPad to capture point clouds.")
    }

    @Test func captureErrorMessageExplainsUnsupportedPlatform() {
        let message = CaptureErrorMessage.from(LidarCaptureSessionError.unsupportedPlatform)

        #expect(message.title == "Scanning is unavailable")
        #expect(message.message == "OpenLidar can capture LiDAR scans only on supported iOS or iPadOS devices.")
    }

    @Test func captureErrorMessageExplainsCameraPermissionFailures() {
        let message = CaptureErrorMessage.fromRawReason("Camera authorization denied")

        #expect(message.title == "Camera access is needed")
        #expect(message.message == "Allow camera access in Settings so OpenLidar can read AR camera and depth frames.")
    }

    @MainActor
    @Test func scannerViewModelConvertsCaptureFailureStateToUserMessage() {
        let model = ScannerViewModel()

        model.handleCaptureStateForTesting(.failed("AR tracking lost"))

        #expect(model.state == .failed("Tracking was interrupted"))
        #expect(model.errorMessage == "Move slowly in a well-lit area with visible surfaces, then restart the scan.")
    }

    @Test func meshFaceClassificationMapsARKitRawValues() {
        #expect(MeshFaceClassification(arMeshRawValue: 0) == .none)
        #expect(MeshFaceClassification(arMeshRawValue: 1) == .wall)
        #expect(MeshFaceClassification(arMeshRawValue: 2) == .floor)
        #expect(MeshFaceClassification(arMeshRawValue: 3) == .ceiling)
        #expect(MeshFaceClassification(arMeshRawValue: 4) == .table)
        #expect(MeshFaceClassification(arMeshRawValue: 5) == .seat)
        #expect(MeshFaceClassification(arMeshRawValue: 6) == .window)
        #expect(MeshFaceClassification(arMeshRawValue: 7) == .door)
        #expect(MeshFaceClassification(arMeshRawValue: 255) == .unknown)
    }

    @Test func meshSnapshotNormalizesClassificationCountToFaceCount() {
        let shortClassifications = MeshSnapshot(
            anchorID: MeshAnchorID(),
            transform: matrix_identity_float4x4,
            vertices: [
                SIMD3<Float>(0, 0, 0),
                SIMD3<Float>(1, 0, 0),
                SIMD3<Float>(0, 1, 0)
            ],
            faces: [
                SIMD3<UInt32>(0, 1, 2),
                SIMD3<UInt32>(0, 2, 1)
            ],
            classifications: [.floor]
        )
        let longClassifications = MeshSnapshot(
            anchorID: MeshAnchorID(),
            transform: matrix_identity_float4x4,
            vertices: [
                SIMD3<Float>(0, 0, 0),
                SIMD3<Float>(1, 0, 0),
                SIMD3<Float>(0, 1, 0)
            ],
            faces: [SIMD3<UInt32>(0, 1, 2)],
            classifications: [.wall, .floor]
        )

        #expect(shortClassifications.classifications == [.floor, .none])
        #expect(longClassifications.classifications == [.wall])
    }

    @Test func meshAnchorStoreTracksAddUpdateRemoveLifecycle() {
        let anchorID = MeshAnchorID()
        var store = MeshAnchorStore()
        let initial = MeshSnapshot(
            anchorID: anchorID,
            transform: matrix_identity_float4x4,
            vertices: [
                SIMD3<Float>(0, 0, 0),
                SIMD3<Float>(1, 0, 0),
                SIMD3<Float>(0, 1, 0)
            ],
            faces: [SIMD3<UInt32>(0, 1, 2)],
            classifications: [.floor]
        )
        let updated = MeshSnapshot(
            anchorID: anchorID,
            transform: matrix_identity_float4x4,
            vertices: [
                SIMD3<Float>(0, 0, 0),
                SIMD3<Float>(2, 0, 0),
                SIMD3<Float>(0, 2, 0),
                SIMD3<Float>(2, 2, 0)
            ],
            faces: [
                SIMD3<UInt32>(0, 1, 2),
                SIMD3<UInt32>(1, 2, 3)
            ],
            classifications: [.floor, .floor]
        )

        let addedSummary = store.apply(.added(initial))
        #expect(addedSummary.anchorCount == 1)
        #expect(addedSummary.vertexCount == 3)
        #expect(addedSummary.faceCount == 1)
        #expect(store[anchorID] == initial)

        let updatedSummary = store.apply(.updated(updated))
        #expect(updatedSummary.anchorCount == 1)
        #expect(updatedSummary.vertexCount == 4)
        #expect(updatedSummary.faceCount == 2)
        #expect(store[anchorID] == updated)

        let removedSummary = store.apply(.removed(anchorID))
        #expect(removedSummary.anchorCount == 0)
        #expect(removedSummary.vertexCount == 0)
        #expect(removedSummary.faceCount == 0)
        #expect(store[anchorID] == nil)
    }

    @Test func meshAnchorStoreComputesWorldBoundsAcrossAnchors() {
        var transform = matrix_identity_float4x4
        transform.columns.3 = SIMD4<Float>(10, 0, -5, 1)
        var store = MeshAnchorStore()

        let summary = store.apply(
            .added(
                MeshSnapshot(
                    anchorID: MeshAnchorID(),
                    transform: transform,
                    vertices: [
                        SIMD3<Float>(0, 0, 0),
                        SIMD3<Float>(2, 3, 4)
                    ],
                    faces: []
                )
            )
        )

        #expect(summary.bounds?.minimum == SIMD3<Float>(10, 0, -5))
        #expect(summary.bounds?.maximum == SIMD3<Float>(12, 3, -1))
    }

    @Test func meshWireframeBuilderCreatesTriangleEdgesInWorldSpace() {
        var transform = matrix_identity_float4x4
        transform.columns.3 = SIMD4<Float>(10, 0, -5, 1)
        let snapshot = MeshSnapshot(
            anchorID: MeshAnchorID(),
            transform: transform,
            vertices: [
                SIMD3<Float>(0, 0, 0),
                SIMD3<Float>(1, 0, 0),
                SIMD3<Float>(0, 0, 1)
            ],
            faces: [SIMD3<UInt32>(0, 1, 2)]
        )

        let segments = MeshWireframeBuilder.lineSegments(from: [snapshot])

        #expect(segments.count == 3)
        #expect(segments[0] == MeshLineSegment(start: SIMD3<Float>(10, 0, -5), end: SIMD3<Float>(11, 0, -5)))
        #expect(segments[1] == MeshLineSegment(start: SIMD3<Float>(11, 0, -5), end: SIMD3<Float>(10, 0, -4)))
        #expect(segments[2] == MeshLineSegment(start: SIMD3<Float>(10, 0, -4), end: SIMD3<Float>(10, 0, -5)))
    }

    @Test func meshWireframeBuilderSkipsInvalidFaces() {
        let snapshot = MeshSnapshot(
            anchorID: MeshAnchorID(),
            transform: matrix_identity_float4x4,
            vertices: [SIMD3<Float>(0, 0, 0)],
            faces: [SIMD3<UInt32>(0, 1, 2)]
        )

        let segments = MeshWireframeBuilder.lineSegments(from: [snapshot])

        #expect(segments.isEmpty)
    }

    @MainActor
    @Test func scannerViewModelUpdatesMeshSummaryFromMeshEvents() {
        let model = ScannerViewModel()
        let anchorID = MeshAnchorID()
        let snapshot = MeshSnapshot(
            anchorID: anchorID,
            transform: matrix_identity_float4x4,
            vertices: [
                SIMD3<Float>(0, 0, 0),
                SIMD3<Float>(1, 0, 0),
                SIMD3<Float>(0, 1, 0)
            ],
            faces: [SIMD3<UInt32>(0, 1, 2)]
        )

        model.processMeshEventForTesting(.added(snapshot))

        #expect(model.meshSummary.anchorCount == 1)
        #expect(model.meshSummary.vertexCount == 3)
        #expect(model.meshSummary.faceCount == 1)
        #expect(model.meshSnapshots == [snapshot])

        model.processMeshEventForTesting(.removed(anchorID))

        #expect(model.meshSummary.anchorCount == 0)
        #expect(model.meshSummary.vertexCount == 0)
        #expect(model.meshSummary.faceCount == 0)
        #expect(model.meshSnapshots.isEmpty)
    }

}
