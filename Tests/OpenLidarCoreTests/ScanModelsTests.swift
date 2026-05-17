import Testing
import OpenLidarCore

@Test func boundsEnclosePoints() {
    let points = [
        PointXYZRGBA(x: 1, y: 2, z: 3),
        PointXYZRGBA(x: -1, y: 4, z: 0)
    ]

    let bounds = AxisAlignedBounds.enclosing(points)

    #expect(bounds?.minimum.x == -1)
    #expect(bounds?.minimum.y == 2)
    #expect(bounds?.minimum.z == 0)
    #expect(bounds?.maximum.x == 1)
    #expect(bounds?.maximum.y == 4)
    #expect(bounds?.maximum.z == 3)
}

