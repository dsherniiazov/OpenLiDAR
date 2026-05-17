import SwiftUI

struct MeshWireframePreviewView: View {
    let snapshots: [MeshSnapshot]
    let bounds: AxisAlignedBounds?

    var body: some View {
        Canvas { context, size in
            let segments = MeshWireframeBuilder.lineSegments(from: snapshots)
            guard !segments.isEmpty else {
                return
            }

            let drawingBounds = bounds ?? AxisAlignedBounds.enclosing(
                segments.flatMap { segment in
                    [
                        PointXYZRGBA(x: segment.start.x, y: segment.start.y, z: segment.start.z),
                        PointXYZRGBA(x: segment.end.x, y: segment.end.y, z: segment.end.z)
                    ]
                }
            )
            guard let drawingBounds else {
                return
            }

            let width = max(0.001, drawingBounds.dimensions.x)
            let depth = max(0.001, drawingBounds.dimensions.z)
            let stroke = StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round)

            for segment in segments {
                var path = Path()
                path.move(to: point(segment.start, in: drawingBounds, width: width, depth: depth, size: size))
                path.addLine(to: point(segment.end, in: drawingBounds, width: width, depth: depth, size: size))
                context.stroke(path, with: .color(.cyan.opacity(0.75)), style: stroke)
            }
        }
        .overlay {
            if snapshots.isEmpty {
                ContentUnavailableView("Mesh Preview", systemImage: "triangle", description: Text("Start scanning on a LiDAR device to preview room mesh surfaces."))
            }
        }
        .background(.black, in: RoundedRectangle(cornerRadius: 8))
    }

    private func point(
        _ vertex: SIMD3<Float>,
        in bounds: AxisAlignedBounds,
        width: Float,
        depth: Float,
        size: CGSize
    ) -> CGPoint {
        CGPoint(
            x: CGFloat((vertex.x - bounds.minimum.x) / width) * size.width,
            y: CGFloat((vertex.z - bounds.minimum.z) / depth) * size.height
        )
    }
}
