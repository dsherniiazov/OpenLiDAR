import SwiftUI

struct PointCloudPreviewView: View {
    let points: [PointXYZRGBA]
    let bounds: AxisAlignedBounds?

    var body: some View {
        Canvas { context, size in
            guard points.isEmpty == false else {
                return
            }

            let drawingBounds = bounds ?? AxisAlignedBounds.enclosing(points)
            guard let drawingBounds else {
                return
            }

            let width = max(0.001, drawingBounds.dimensions.x)
            let depth = max(0.001, drawingBounds.dimensions.z)

            for point in points {
                let x = CGFloat((point.x - drawingBounds.minimum.x) / width) * size.width
                let y = CGFloat((point.z - drawingBounds.minimum.z) / depth) * size.height
                let color = Color(
                    red: Double(point.red) / 255,
                    green: Double(point.green) / 255,
                    blue: Double(point.blue) / 255,
                    opacity: Double(point.alpha) / 255
                )

                context.fill(
                    Path(ellipseIn: CGRect(x: x - 1, y: y - 1, width: 2, height: 2)),
                    with: .color(color)
                )
            }
        }
        .overlay {
            if points.isEmpty {
                ContentUnavailableView("Point Preview", systemImage: "square.grid.3x3", description: Text("Start scanning to preview sampled points."))
            }
        }
        .background(.black, in: RoundedRectangle(cornerRadius: 8))
    }
}

