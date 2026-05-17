import Foundation

enum PreviewPerformancePreset: String, CaseIterable, Identifiable {
    case smooth
    case balanced
    case detailed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .smooth:
            "Smooth"
        case .balanced:
            "Balanced"
        case .detailed:
            "Detailed"
        }
    }

    var targetFramesPerSecond: Int {
        switch self {
        case .smooth:
            5
        case .balanced:
            8
        case .detailed:
            12
        }
    }

    var livePointBudget: Int {
        switch self {
        case .smooth:
            4_000
        case .balanced:
            10_000
        case .detailed:
            25_000
        }
    }

    var previewPointBudget: Int {
        switch self {
        case .smooth:
            900
        case .balanced:
            1_800
        case .detailed:
            3_000
        }
    }
}

enum SaveQualityPreset: String, CaseIterable, Identifiable {
    case light
    case balanced
    case maximum

    var id: String { rawValue }

    var title: String {
        switch self {
        case .light:
            "Light"
        case .balanced:
            "Balanced"
        case .maximum:
            "Maximum"
        }
    }

    var accumulatedPointLimit: Int {
        switch self {
        case .light:
            200_000
        case .balanced:
            600_000
        case .maximum:
            1_500_000
        }
    }

    var compactionTarget: Int {
        switch self {
        case .light:
            150_000
        case .balanced:
            450_000
        case .maximum:
            1_000_000
        }
    }
}

