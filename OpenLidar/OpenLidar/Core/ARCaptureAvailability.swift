#if os(iOS) && canImport(ARKit)
import ARKit
#endif

public enum ARCaptureAvailability {
    public static var current: DeviceCapabilities {
        var capabilities: Set<CaptureCapability> = []

        #if os(iOS) && canImport(ARKit)
        if ARWorldTrackingConfiguration.isSupported {
            capabilities.insert(.worldTracking)
        }

        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            capabilities.insert(.sceneDepth)
        }

        if ARWorldTrackingConfiguration.supportsFrameSemantics(.smoothedSceneDepth) {
            capabilities.insert(.smoothedSceneDepth)
        }

        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            capabilities.insert(.lidarMeshReconstruction)
        }
        #endif

        return DeviceCapabilities(supported: capabilities)
    }
}
