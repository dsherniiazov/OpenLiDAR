# Performance Notes

Apple's point-cloud sample uses Metal textures and `MTKView` for live visualization. That is the correct long-term path for high-quality preview. The current implementation now uses a lower-risk intermediate path so capture remains responsive before the Metal rewrite.

## Implemented Now

- Throttle depth processing to the selected preview preset FPS.
- Keep live point budgets low by default.
- Draw only a small sampled point preview in SwiftUI `Canvas`.
- Keep saved capture accumulation bounded with save-quality presets.
- Apply lightweight point color presets without expensive camera RGB sampling.

## Presets

Preview:
- Smooth: 5 FPS processing, 4k live points, 900 preview points.
- Balanced: 8 FPS processing, 10k live points, 1.8k preview points.
- Detailed: 12 FPS processing, 25k live points, 3k preview points.

Save:
- Light: compact at 200k points.
- Balanced: compact at 600k points.
- Maximum: compact at 1.5M points.

Color:
- Original.
- White.
- Green.
- Confidence grayscale.
- Height gradient.

## Next Optimization Steps

- Replace CPU depth copying with `CVMetalTextureCache`.
- Move depth projection and confidence filtering into Metal compute.
- Draw point preview with `MTKView`.
- Add camera RGB sampling on GPU.
- Add voxel downsampling on GPU or SIMD.

