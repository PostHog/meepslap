import Foundation
import Combine

enum SensitivityLevel: Int, CaseIterable {
    case veryLow = 0, low, medium, high, veryHigh

    var displayName: String {
        switch self {
        case .veryLow: return "Requires Significant Force"
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .veryHigh: return "Extremely Sensitive"
        }
    }

    /// Thresholds derived from on-device captures: hard typing peaks at
    /// ~0.12 g with low coincident jerk, so even the most sensitive level
    /// (amp 0.15 g AND jerk 14 g/s) rejects it with margin, while real slaps
    /// (≥0.5 g and tens–hundreds g/s of jerk) clear every level.
    var detectorConfig: DetectorConfig {
        switch self {
        case .veryHigh:   // "Extremely Sensitive" — soft slaps count, typing doesn't
            return DetectorConfig(ampThreshold: 0.15, jerkThreshold: 14, hardAmpThreshold: 0.45)
        case .high:
            return DetectorConfig(ampThreshold: 0.25, jerkThreshold: 20, hardAmpThreshold: 0.60)
        case .medium:
            return DetectorConfig(ampThreshold: 0.40, jerkThreshold: 30, hardAmpThreshold: 0.90)
        case .low:
            return DetectorConfig(ampThreshold: 0.70, jerkThreshold: 50, hardAmpThreshold: 1.50)
        case .veryLow:    // "Requires Significant Force" — only firm/hard slaps
            return DetectorConfig(ampThreshold: 1.10, jerkThreshold: 90, hardAmpThreshold: 2.20)
        }
    }
}

enum CooldownOption: Double, CaseIterable {
    case none = 0.0
    case fast = 0.35
    case medium = 0.75
    case long = 1.0
    case veryLong = 2.0

    var displayName: String {
        switch self {
        case .none: return "None"
        case .fast: return "Fast (0.35s)"
        case .medium: return "Medium (0.75s)"
        case .long: return "Slow (1.0s)"
        case .veryLong: return "Very Slow (2.0s)"
        }
    }

    var interval: Double { rawValue }
}

/// Persisted user settings, all backed by UserDefaults. Stripped down from the
/// original MacSlapApp: just slap sensitivity/cooldown, master volume,
/// dynamic-volume scaling, the optional screen-flash garnish, and the slap
/// counter. No voice packs, no USB moaner, no private-API effects.
class SettingsStore: ObservableObject {
    private let defaults = UserDefaults.standard

    @Published var isEnabled: Bool {
        didSet { defaults.set(isEnabled, forKey: "isEnabled") }
    }
    @Published var sensitivity: SensitivityLevel {
        didSet { defaults.set(sensitivity.rawValue, forKey: "sensitivity") }
    }
    @Published var cooldownInterval: Double {
        didSet { defaults.set(cooldownInterval, forKey: "cooldown") }
    }
    @Published var dynamicVolume: Bool {
        didSet { defaults.set(dynamicVolume, forKey: "dynamicVolume") }
    }
    @Published var totalSlapCount: Int {
        didSet { defaults.set(totalSlapCount, forKey: "totalSlapCount") }
    }
    @Published var showCountInMenuBar: Bool {
        didSet { defaults.set(showCountInMenuBar, forKey: "showCountInMenuBar") }
    }
    @Published var screenFlashEnabled: Bool {
        didSet { defaults.set(screenFlashEnabled, forKey: "screenFlashEnabled") }
    }
    @Published var screenFlashIntensity: Double {
        didSet { defaults.set(screenFlashIntensity, forKey: "screenFlashIntensity") }
    }
    @Published var volume: Float {
        didSet { defaults.set(volume, forKey: "volume") }
    }

    init() {
        let d = UserDefaults.standard
        self.isEnabled = d.object(forKey: "isEnabled") as? Bool ?? true
        self.sensitivity = SensitivityLevel(rawValue: d.integer(forKey: "sensitivity")) ?? .medium
        self.cooldownInterval = d.object(forKey: "cooldown") as? Double ?? 0.75
        self.dynamicVolume = d.object(forKey: "dynamicVolume") as? Bool ?? true
        self.totalSlapCount = d.integer(forKey: "totalSlapCount")
        self.showCountInMenuBar = d.object(forKey: "showCountInMenuBar") as? Bool ?? true
        self.screenFlashEnabled = d.object(forKey: "screenFlashEnabled") as? Bool ?? false
        self.screenFlashIntensity = d.object(forKey: "screenFlashIntensity") as? Double ?? 0.5
        self.volume = d.object(forKey: "volume") as? Float ?? 0.8
    }
}
