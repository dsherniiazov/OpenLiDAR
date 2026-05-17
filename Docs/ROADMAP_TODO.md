# OpenLidar Roadmap TODO

This file is the live task tracker for OpenLidar. Update checkboxes as features are implemented and verified.

Legend:
- `[x]` implemented and at least build-verified.
- `[~]` partially implemented or scaffolded.
- `[ ]` not implemented.

## Current Verified State

- [x] Xcode iOS project exists at `OpenLidar/OpenLidar.xcodeproj`.
- [x] App builds for generic iOS with `xcodebuild`.
- [x] SwiftUI scanner dashboard replaces the default template UI.
- [x] AR preview surface exists through `ARView`.
- [x] ARKit LiDAR session setup exists.
- [x] Device capability detection exists for world tracking, scene depth, smoothed scene depth, and LiDAR mesh support.
- [x] CPU depth map to point cloud projection exists.
- [x] Near/far depth clipping controls exist.
- [x] Live point chunk generation exists.
- [x] Session-level point accumulation exists with a memory cap/downsampling fallback.
- [x] Scan duration timer exists.
- [x] Scan bounds calculation and display exists.
- [x] Lightweight point cloud preview exists.
- [x] Preview/save/color presets exist.
- [x] ASCII PLY point cloud export exists.
- [x] XYZ, OBJ, PTS, CSV, and JSON point cloud exports exist.
- [x] UDP binary packet encoder and sender exist.
- [x] Camera permission is configured.
- [~] SwiftPM package still exists as a reusable/module test scaffold, but the active app code now lives inside the Xcode project.
- [ ] Physical iPhone LiDAR runtime test has not been verified yet.
- [ ] TouchDesigner receiver has not been implemented yet.

## Polycam Capability Gap Analysis

Researched on 2026-05-17 from Polycam public docs:
- Capture modes: Space, Object, Floorplan, AI Capture, 360 Mode.
  Source: https://learn.poly.cam/hc/en-us/articles/48565771018772-Which-Capture-Mode-Should-I-Use
- Space Mode on LiDAR creates a detailed 3D LiDAR mesh, 3D floorplan model, and 2D floorplan with measurements.
  Source: https://learn.poly.cam/hc/en-us/articles/36655587097620-How-to-Use-Space-Mode-with-LiDAR-enabled-devices
- Object Mode supports photogrammetry meshes and Gaussian Splats.
  Source: https://learn.poly.cam/hc/en-us/articles/27425185907348-How-to-Use-Object-Mode
- Export formats include major mesh, point cloud, floorplan, image, and video outputs, with plan-dependent access.
  Source: https://learn.poly.cam/hc/en-us/articles/27756102599572-What-File-Types-Can-Polycam-Export
- Measurement, crop/rotate, Explore publishing, web/team collaboration, spatial reports, and drone photogrammetry are separate product capabilities.
  Sources:
  - https://learn.poly.cam/hc/en-us/articles/29647317758100-How-to-take-Measurements-in-Polycam
  - https://learn.poly.cam/hc/en-us/articles/29647360522516-How-to-Crop-and-Rotate-a-Capture-in-Polycam
  - https://learn.poly.cam/hc/en-us/articles/27646618932116-Publishing-Your-Own-Captures-to-Explore
  - https://learn.poly.cam/hc/en-us/articles/35145054767124-How-to-Generate-a-Spatial-Report
  - https://learn.poly.cam/hc/en-us/articles/30549134403860

OpenLidar should treat Polycam as a capability benchmark, not as a UI, branding, or closed-algorithm clone.
Local-first behavior remains a product constraint unless an optional PC/cloud pipeline is explicitly introduced.

### Gap Matrix

| Polycam capability | OpenLidar state | Gap | Clean-code / TDD plan |
| --- | --- | --- | --- |
| LiDAR space scan | [~] Point-cloud capture exists; real-device verification missing | No verified runtime quality, mesh lifecycle, RGB color, drift recovery, or high-quality persistence | Add fixture-driven projector/downsampler tests first, then real-device smoke checklist; keep `LidarCaptureSession` as ARKit adapter and move scan-state decisions into pure testable services |
| 3D LiDAR mesh | [ ] Planned in Phase 4 | No `ARMeshAnchor` domain model, preview, persistence, or mesh exporters | Define `MeshAnchorSnapshot`, `MeshStore`, and `MeshExporter` protocols; write add/update/remove lifecycle tests before ARKit wiring |
| 2D/3D floorplans | [ ] Planned in Phase 8 | No RoomPlan flow, room labels, dimensions, doors/windows, or PDF/SVG output | Wrap RoomPlan behind `RoomCaptureService`; start with fixture JSON to test room-to-floorplan conversion, then add UI and export contract tests |
| Object photogrammetry | [ ] Planned in Phase 9 | No guided photo capture, image quality checks, local reconstruction integration, or dataset fallback | Build capture image-set model first; TDD blur/exposure/overlap validators with static fixtures; keep reconstruction as replaceable backend |
| Gaussian Splats | [ ] Planned in Phase 10 | No splat capture UX, Nerfstudio/gsplat dataset validation, or PC launcher | Treat as dataset export first; test `transforms.json`, frame naming, intrinsics, and pose conversion with golden fixtures before any trainer integration |
| AI single-image 3D capture | [ ] Not planned | Polycam has AI Capture; OpenLidar has no cloud/AI generator | Add as optional research only; preserve local-first core by requiring a separate `ModelGenerationService` boundary and mocked API tests if implemented |
| 360 panorama | [ ] Not planned | No panorama capture, stitching, skybox export, or viewer | Add a later `PanoramaCapture` module; begin with orientation/path model tests and export metadata fixtures before image stitching work |
| Drone/aerial photogrammetry | [ ] Not planned | No drone media import, GPS EXIF pipeline, georeferenced outputs, or large-scene processing | PC-side research task first; test EXIF parsing, geospatial metadata normalization, and dataset packaging separately from mobile app |
| Measurements | [ ] Planned in Phase 11 | No distance/area/volume tools or saved measurements | Create pure geometry measurement library with unit tests for distance, polyline, polygon area, bounds volume, units, and invalid input |
| Editing/cropping | [ ] Planned in Phase 11 | No crop volumes, delete region, floor alignment, scale verification, undo/redo | Use command-pattern edit model with undo/redo tests; apply edits to point clouds and meshes through shared geometry interfaces |
| Export breadth | [~] Point export exists; many formats missing | Missing binary PLY, mesh PLY/OBJ/USDZ, glTF/GLB, STL, LAS/LAZ, DXF, floorplan PDF/PNG/SVG | One exporter per module; every exporter needs golden-file tests, import/parse validation where possible, and clear format limitation docs |
| Library and sharing | [~] In-memory saved scans/gallery scaffold exists | No durable library, albums, thumbnails, web viewer, share links, comments, or team workflow | Finish local `ScanRecord` store before sharing; keep sync/collaboration optional behind repository interfaces and test with local fake stores |
| Guided capture UX | [~] Basic scanner UI exists | Missing mode picker, preparation hints, quality guidance, progress coverage, manual/auto capture concepts, and recovery prompts | Model guidance as testable `CaptureGuidanceEngine`; feed synthetic frame metrics and assert exact user-facing states |
| Web/team/community features | [ ] Not planned | Polycam has Explore, web app, team spaces, comments/annotations | Non-MVP; if added, design as separate service layer so local capture/export modules remain usable without accounts or network |

### Clean Code And TDD Rules For Polycam-Parity Work

- [ ] Add a failing unit or fixture test before changing capture, processing, storage, export, protocol, or geometry behavior.
- [ ] Keep ARKit, RoomPlan, networking, file system, and future cloud/PC integrations behind small protocols with fake implementations for tests.
- [ ] Put reusable domain logic in `Sources/OpenLidarCore`, export logic in `Sources/ScanExport`, stream logic in `Sources/ScanStreaming`, and keep SwiftUI views thin.
- [ ] Prefer immutable value models for scan records, point chunks, mesh snapshots, room/floorplan entities, measurements, and export jobs.
- [ ] Add golden fixtures for every file/protocol format: PLY, OBJ, glTF/GLB, USDZ metadata, SVG/PDF floorplan, stream packets, and Gaussian Splat datasets.
- [ ] Split each large feature into: model tests, parser/serializer tests, service tests with fakes, UI smoke/snapshot test, then real-device checklist.
- [ ] Require explicit acceptance criteria on each new roadmap item before implementation starts.
- [ ] Add performance budgets to tests or benchmarks when touching frame processing, downsampling, mesh conversion, streaming, or export.
- [ ] Document every intentional Polycam gap as either local-first constraint, MVP deferral, platform limitation, or explicit non-goal.
- [ ] If the same build/test/runtime error appears twice, research 3-5 fixes online, choose the best fix, implement it, and document the decision.

## Phase 1: Stabilize LiDAR MVP

- [ ] Test on a real LiDAR iPhone/iPad.
- [ ] Verify camera permission prompt and AR session startup.
- [ ] Verify `sceneDepth` and `smoothedSceneDepth` are actually producing depth frames.
- [ ] Verify point coordinates are correctly oriented in world space.
- [x] Add runtime fallback UI for non-LiDAR devices.
- [x] Add AR session error messages that are readable for normal users.
- [x] Add pause/resume behavior that does not lose current accumulated scan unless requested.
- [ ] Add "New Scan" flow with confirmation before clearing accumulated points.
- [x] Add scan duration timer.
- [ ] Add dropped-frame / generated-chunk counters.
- [ ] Add thermal state monitoring.
- [ ] Auto-reduce capture density when thermal state rises.
- [ ] Auto-reduce capture density when frame processing falls behind.
- [x] Add simple point cloud preview overlay or RealityKit point visualization.
- [ ] Add basic scan quality hints: move slower, too dark, not enough depth confidence.
- [ ] Add capture guidance engine tests for movement speed, low light, low confidence, tracking loss, and drift recovery prompts.
- [ ] Add haptic/visual feedback plan for active capture and successful frame ingestion.
- [x] Add save/export success UI with actual file location/share sheet.
- [x] Add saved scan list after stopping a scan.
- [x] Add per-scan export controls.

## Phase 2: Local Scan Storage

- [ ] Define persistent `ScanRecord` metadata model.
- [ ] Decide whether to use SwiftData for metadata or plain JSON index first.
- [ ] Store raw scan sessions in `Documents/OpenLidar/Scans/<scan-id>/`.
- [ ] Save `metadata.json` per scan.
- [ ] Add fixture tests for `ScanRecord` encode/decode and migration.
- [ ] Save point chunks incrementally instead of keeping everything only in memory.
- [ ] Save camera poses per frame.
- [ ] Save camera intrinsics per session.
- [ ] Save depth frame references when dataset export is enabled.
- [~] Add scan gallery screen.
- [ ] Add scan details screen.
- [ ] Add delete scan.
- [ ] Add rename scan.
- [ ] Add duplicate/export scan.
- [ ] Add scan albums/tags research task.
- [ ] Add thumbnail generation with deterministic fixture tests.
- [ ] Add storage usage display.
- [ ] Add cleanup for interrupted/incomplete sessions.

## Phase 3: Better Point Cloud Processing

- [ ] Replace full CPU depth copy path with a Metal-backed path.
- [ ] Use `CVMetalTextureCache` for depth map access.
- [ ] Add GPU confidence filtering.
- [ ] Add GPU or SIMD voxel downsampling.
- [ ] Add color sampling from camera image.
- [ ] Add RGB/RGBA color to exported points.
- [x] Add configurable point density presets: Low, Balanced, High.
- [x] Add near/far clipping controls.
- [ ] Filter invalid depth spikes.
- [ ] Add temporal smoothing option.
- [ ] Add world-space voxel merge to reduce duplicate points.
- [x] Add scan bounds calculation and display.
- [ ] Add unit tests for projector math and downsampling.
- [ ] Add performance benchmark harness for point generation.

## Phase 4: Mesh Scan

- [x] Capture `ARMeshAnchor` updates.
- [x] Store mesh anchors by stable anchor identifier.
- [x] Track mesh anchor add/update/remove events.
- [~] Convert `ARMeshGeometry` vertices/faces to app mesh format.
- [x] Preserve mesh classification when available.
- [~] Add mesh preview mode.
- [x] Export mesh to PLY.
- [x] Export mesh to OBJ.
- [ ] Export mesh to USDZ.
- [ ] Add mesh simplification option.
- [x] Add normal generation.
- [ ] Add optional vertex coloring from camera frames.
- [ ] Add chunked mesh persistence.
- [ ] Add mesh scan quality metrics.
- [x] Add mesh lifecycle tests for anchor add/update/remove before ARKit integration.
- [x] Add mesh exporter golden-file tests before enabling mesh export UI.

## Phase 5: Exports

- [x] ASCII PLY point export.
- [x] XYZ point export.
- [x] OBJ point vertex export.
- [x] PTS point export.
- [x] CSV point export.
- [x] JSON point export.
- [ ] Binary PLY point export.
- [x] PLY mesh export.
- [x] OBJ mesh export.
- [ ] USDZ mesh export.
- [ ] glTF/GLB export.
- [ ] STL export research and implementation decision.
- [ ] DXF export research for floorplan and point/mesh use cases.
- [ ] LAS/LAZ research and implementation decision.
- [ ] Geo-referenced LAS research and non-goal/roadmap decision.
- [ ] DAE/FBX export research and converter-vs-native decision.
- [ ] Export progress UI.
- [x] iOS share sheet integration.
- [ ] Background-safe export task handling.
- [x] Export validation tests with small fixtures.
- [ ] Export README with supported formats and limitations.

## Phase 6: Streaming To PC And TouchDesigner

- [x] UDP binary packet envelope.
- [x] UDP point chunk sender.
- [~] Streaming UI for host/port exists.
- [ ] Add OSC sender for pose/status.
- [ ] Add packet type for camera pose.
- [ ] Stream camera pose at 30-60 Hz.
- [ ] Add packet type for status/stats.
- [ ] Add packet type for quantized binary point chunks.
- [ ] Replace JSON point payload with compact binary payload.
- [ ] Add packet loss sequence tracking.
- [ ] Add receiver heartbeat.
- [ ] Add connection status UI.
- [ ] Add QR pairing flow.
- [ ] Add local network permission handling and explanation.
- [ ] Add Bonjour discovery for PC receiver.
- [ ] Add WebSocket debug transport.
- [ ] Create `TouchDesigner/OpenLidar.tox` receiver.
- [ ] Create TouchDesigner OSC example network.
- [ ] Create TouchDesigner point cloud Script SOP prototype.
- [ ] Document TouchDesigner setup with screenshots.

## Phase 7: Dedicated PC Receiver

- [ ] Create `Tools/PCReceiver/` project.
- [ ] Choose implementation language: Rust recommended, C++ only where TouchDesigner ABI requires it.
- [ ] Implement UDP binary receiver.
- [ ] Implement session metadata receiver.
- [ ] Add live point cloud renderer.
- [ ] Add packet recording.
- [ ] Add playback from recorded stream.
- [ ] Add PLY export on PC.
- [ ] Add OBJ/glTF export on PC if mesh stream exists.
- [ ] Add Spout output for Windows TouchDesigner.
- [ ] Add Syphon output for macOS TouchDesigner.
- [ ] Add shared memory bridge.
- [ ] Prototype TouchDesigner C++ TOP/SOP plugin.
- [ ] Add receiver build instructions.

## Phase 8: RoomPlan / Floorplan Mode

- [ ] Add RoomPlan availability detection.
- [ ] Add RoomPlan capture screen.
- [ ] Add guided room scan UI.
- [ ] Save `CapturedRoom` result.
- [ ] Export RoomPlan USD/USDZ.
- [ ] Generate 2D floorplan preview.
- [ ] Export SVG floorplan.
- [ ] Export PDF floorplan.
- [ ] Add dimensions display.
- [ ] Add room labels and editable room names.
- [ ] Add spatial report research task.
- [ ] Add fixture tests for room dimensions, door/window extraction, and floorplan SVG coordinates.
- [ ] Add doors/windows/furniture visibility toggles.
- [ ] Add multi-room capture research task.
- [ ] Add multi-floor capture research task.
- [ ] Add RoomPlan limitations document.

## Phase 9: Object Capture Mode

- [ ] Add object capture mode screen.
- [ ] Add guided photo collection UI.
- [ ] Store object capture image set.
- [ ] Store camera poses/intrinsics where available.
- [ ] Integrate RealityKit Object Capture where supported.
- [ ] Add fallback dataset export when local reconstruction is unavailable.
- [ ] Add turntable/free-move capture guidance.
- [ ] Add image quality checks: blur, exposure, overlap.
- [ ] Add static-image fixture tests for blur and exposure scoring.
- [ ] Add capture coverage/progress model tests before UI implementation.
- [ ] Export reconstructed model to USDZ.
- [ ] Add object scan gallery integration.

## Phase 10: Gaussian Splat Dataset Pipeline

- [ ] Add Gaussian Splat capture mode.
- [ ] Add Gaussian Splatting reconstruction/training workflow.
- [ ] Save RGB frames.
- [ ] Save camera poses.
- [ ] Save camera intrinsics.
- [ ] Save optional depth maps.
- [ ] Save seed point cloud.
- [ ] Export Nerfstudio-compatible dataset.
- [ ] Export `transforms.json`.
- [ ] Add PC-side `gsplat`/Nerfstudio launcher plan.
- [ ] Add documentation for training on PC.
- [ ] Add sample dataset validation.
- [ ] Add golden dataset test for frame paths, intrinsics, poses, depth refs, and seed point cloud.

## Phase 10A: Optional AI, 360, And Aerial Capture Research

- [ ] Decide whether AI Capture belongs in OpenLidar or remains a non-goal because of local-first constraints.
- [ ] If AI Capture is approved, define `ModelGenerationService` protocol before any provider-specific code.
- [ ] Add mocked contract tests for single-image model generation request/response handling.
- [ ] Research 360 panorama capture, stitching, skybox export, and viewer requirements.
- [ ] Add `PanoramaCapture` domain model and orientation/path tests before UI work.
- [ ] Research drone/aerial photogrammetry as a PC-side import pipeline.
- [ ] Add EXIF/GPS parsing fixture tests for drone media if aerial import is approved.
- [ ] Decide whether web viewer/share links are local static exports, self-hosted, or out of scope.

## Phase 11: Measurements And Editing

- [ ] Add tap-to-measure distance.
- [ ] Add area measurement.
- [ ] Add volume/bounds estimate.
- [ ] Add manual crop box.
- [ ] Add point cloud crop.
- [ ] Add mesh crop.
- [ ] Add cylinder crop research task for parity with common capture-edit tools.
- [ ] Add delete selected region.
- [ ] Add floor alignment tool.
- [ ] Add scale verification tool.
- [ ] Add undo/redo model for edits.
- [ ] Add geometry unit tests for distance, area, volume, crop inclusion, crop inversion, alignment, and edit undo/redo.

## Phase 12: UI/UX Polish

- [x] Replace temporary dashboard with production scanner layout.
- [ ] Add mode selector: LiDAR, Room, Object, Splat.
- [ ] Add scan gallery.
- [ ] Add settings screen.
- [ ] Add export sheet.
- [x] Add streaming settings sheet.
- [ ] Add device capability warning screen.
- [ ] Add first-run onboarding.
- [ ] Add clear visual capture states.
- [ ] Add preparation checklist for lighting, reflective surfaces, movement path, and storage/battery.
- [ ] Add manual/auto capture mode research for Space/Object workflows.
- [ ] Add accessible labels for controls.
- [ ] Add dark/light mode review.
- [ ] Add iPad layout pass.
- [ ] Add localization structure.

## Phase 13: Reliability And Testing

- [ ] Add unit tests inside Xcode test target for projector math.
- [ ] Add unit tests for PLY export.
- [ ] Add unit tests for binary packet codec.
- [ ] Add snapshot or UI tests for main scanner screen.
- [ ] Add runtime smoke test checklist for real LiDAR device.
- [ ] Add memory profiling checklist.
- [ ] Add thermal profiling checklist.
- [ ] Add network streaming soak test.
- [ ] Add export/import fixture tests.
- [ ] Add crash-safe scan persistence tests.
- [ ] Add CI build script.
- [ ] Add `make build-ios` or `Scripts/build_ios.sh`.

## Phase 14: App Store / Distribution Readiness

- [ ] Add real app icon.
- [ ] Add privacy manifest if required by used APIs.
- [ ] Review camera/local network privacy strings.
- [ ] Add local network usage description when streaming/discovery needs it.
- [ ] Add export format documentation in-app or README.
- [ ] Add license file.
- [ ] Add README with build instructions.
- [ ] Add screenshots.
- [ ] Add TestFlight checklist.
- [ ] Add known limitations document.

## Implementation Priority

1. Real device LiDAR validation.
2. Save scans incrementally to disk.
3. Compact binary streaming payload.
4. TouchDesigner receiver prototype.
5. Mesh anchor capture/export.
6. RoomPlan mode.
7. Object Capture mode.
8. Gaussian Splat dataset export.
9. PC receiver.
10. UI polish and release hardening.
11. Polycam-parity guided capture and measurement/editing polish.
12. Optional 360, AI Capture, aerial photogrammetry, and web/team sharing decisions.
