import Foundation
import Combine

/// Wires the accelerometer → impact detector → reaction (audio + optional
/// screen flash). The controller owns the long-lived sensor reader and the
/// meep player; the menu bar UI talks to it through the published settings.
class MeepSlapController: ObservableObject {
    let meepPlayer = MeepPlayer()
    let screenFlash = ScreenFlash()
    private let accelerometer = AccelerometerReader()
    private var slapDetector: SlapDetector
    private let settings: SettingsStore

    private var lastSlapTime: Date = .distantPast

    init(settings: SettingsStore) {
        self.settings = settings
        self.slapDetector = SlapDetector(config: settings.sensitivity.detectorConfig)

        screenFlash.intensityMultiplier = settings.screenFlashIntensity * 2.0

        // Wire up slap detection
        slapDetector.onSlap = { [weak self] event in
            self?.handleSlap(event)
        }

        // Wire up accelerometer -> detector
        accelerometer.onSample = { [weak self] x, y, z in
            self?.slapDetector.processSample(x: x, y: y, z: z)
        }
    }

    func start() {
        let success = accelerometer.start()
        if !success {
            log("WARNING: Could not start accelerometer")
            log("This Mac may not have a compatible sensor (requires M1+ MacBook)")
        }
    }

    func stop() {
        accelerometer.stop()
    }

    func updateDetectorConfig() {
        slapDetector.updateConfig(settings.sensitivity.detectorConfig)
    }

    /// Manual meep for the "Test Meep" menu item.
    func testMeep() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.meepPlayer.play(intensity: 0.6,
                                 dynamicVolume: self.settings.dynamicVolume,
                                 baseVolume: self.settings.volume)
            if self.settings.screenFlashEnabled {
                self.screenFlash.flash(intensity: 0.6)
            }
        }
    }

    private func handleSlap(_ event: SlapEvent) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Enforce user-facing cooldown
            let now = Date()
            guard now.timeIntervalSince(self.lastSlapTime) >= self.settings.cooldownInterval else { return }
            self.lastSlapTime = now

            // 1. Play the meep
            self.meepPlayer.play(intensity: event.intensity,
                                 dynamicVolume: self.settings.dynamicVolume,
                                 baseVolume: self.settings.volume)

            // 2. Optional screen flash garnish
            if self.settings.screenFlashEnabled {
                self.screenFlash.flash(intensity: event.intensity)
            }

            // Update count
            self.settings.totalSlapCount += 1
            NotificationCenter.default.post(name: .slapCountChanged, object: nil)

            log("\(event.severity.rawValue) amp=\(String(format: "%.4f", event.magnitude))g " +
                  "vol=\(String(format: "%.0f%%", event.intensity * 100)) " +
                  "detectors=\(event.sources.sorted().joined(separator: "+")) " +
                  "total=\(self.settings.totalSlapCount)")
        }
    }
}
