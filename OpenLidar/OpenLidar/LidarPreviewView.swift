import SwiftUI

#if os(iOS) && canImport(ARKit) && canImport(RealityKit)
import ARKit
import RealityKit

struct LidarPreviewView: UIViewRepresentable {
    let session: ARSession?

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero)
        view.renderOptions.insert(.disableMotionBlur)
        view.automaticallyConfigureSession = false
        if let session {
            view.session = session
        }
        return view
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        if let session, uiView.session !== session {
            uiView.session = session
        }
    }
}
#else
struct LidarPreviewView: View {
    var session: Any?

    var body: some View {
        Rectangle()
            .fill(.black.opacity(0.08))
            .overlay {
                Text("AR preview is available on iOS devices")
                    .foregroundStyle(.secondary)
            }
    }
}
#endif

