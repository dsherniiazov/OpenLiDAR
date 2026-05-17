# OpenLidar Streaming Protocol

## Goals

- Keep TouchDesigner setup simple for pose/status data.
- Keep high-rate point cloud and mesh streams out of OSC where possible.
- Allow lossy live preview while preserving full-quality local scan data.

## Transport Split

### OSC

Use OSC for low-bandwidth control and status:

```text
/openlidar/hello appVersion deviceName capabilities
/openlidar/state stateName
/openlidar/pose timestamp tx ty tz qx qy qz qw
/openlidar/stats fps pointCount droppedPackets thermalState
```

TouchDesigner operators:
- `OSC In CHOP` for numeric channels.
- `OSC In DAT` for debugging messages.

### UDP Binary

Use UDP for live point cloud chunks. Packets may be dropped. Receivers should use sequence numbers to detect loss and keep the most recent complete visual state.

Header layout, big-endian:

```text
uint32 magic      "OLDR" / 0x4F4C4452
uint8  version    1
uint8  type       packet type
uint64 sequence
uint64 timestampNanoseconds
uint32 payloadSize
bytes  payload
```

Current packet types:

```text
1 hello
2 pose
3 pointCloudChunk
4 status
```

The current Swift MVP encodes payloads as JSON for development visibility. The production path should switch point payloads to a quantized binary format:

```text
float32 originX originY originZ
float32 scaleX scaleY scaleZ
uint32 pointCount
repeated point:
  int16 x y z
  uint8 r g b a
  uint8 confidence
```

## TouchDesigner MVP

1. Receive OSC pose/status with `OSC In CHOP` and `OSC In DAT`.
2. Receive point chunks either through:
   - WebSocket DAT for small/debug payloads.
   - A lightweight Python UDP receiver DAT for MVP.
3. For high-rate rendering, use the future PC receiver and shared memory/C++ plugin instead of Python row parsing.

## PC Receiver Direction

The dedicated receiver should:
- Pair with iOS via QR code containing host/port/session key.
- Receive UDP point chunks and reliable metadata.
- Render point clouds with `wgpu`.
- Record raw stream packets.
- Export PLY/OBJ/glTF and Nerfstudio datasets.
- Bridge frames to TouchDesigner via Spout/Syphon/shared memory.
