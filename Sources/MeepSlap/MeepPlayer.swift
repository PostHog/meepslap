import Foundation
import AVFoundation

/// Plays the PostHog meep sound on impact.
///
/// One meep clip is bundled for hard slaps (`meep.mp3`) and a shorter, softer
/// one for light taps (`meep-smol.mp3`) — so a gentle bop gives a small meep
/// and a real slap gives the full meep. Each clip has a small pool of
/// `AVAudioPlayer`s so rapid slaps overlap instead of cutting each other off.
class MeepPlayer {
    /// Light taps (below this intensity) get the small meep.
    private let smolThreshold = 0.30

    private var bigPlayers: [AVAudioPlayer] = []
    private var smolPlayers: [AVAudioPlayer] = []
    private var bigIndex = 0
    private var smolIndex = 0

    /// Pool size per clip — enough that a flurry of slaps can overlap.
    private let poolSize = 6

    init() {
        loadSounds()
    }

    private func loadSounds() {
        bigPlayers = makePool(name: "meep")
        smolPlayers = makePool(name: "meep-smol")
        log("Loaded meep sounds: \(bigPlayers.count) big, \(smolPlayers.count) smol")
    }

    /// Builds a player pool for a bundled clip (`.mp3`). Returns an empty array
    /// if the resource is missing, which `play` handles gracefully.
    ///
    /// Resources are declared in Package.swift and bundled by SwiftPM, which
    /// exposes them through the generated `Bundle.module` accessor (NOT
    /// `Bundle.main` — that's empty for a raw executable run outside an .app).
    private func makePool(name: String) -> [AVAudioPlayer] {
        guard let url = Bundle.module.url(forResource: name, withExtension: "mp3") else {
            log("Missing bundled audio resource: \(name).mp3")
            return []
        }
        var pool: [AVAudioPlayer] = []
        for _ in 0..<poolSize {
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                pool.append(player)
            } catch {
                log("Failed to load \(name).mp3: \(error)")
            }
        }
        return pool
    }

    /// Play a meep scaled to the impact.
    /// - Parameters:
    ///   - intensity: 0…1 from the slap detector (peak force).
    ///   - dynamicVolume: when true, intensity scales the per-clip volume
    ///     logarithmically (gentle taps whisper, hard slaps full-volume).
    ///   - baseVolume: master volume, 0…1.
    func play(intensity: Double, dynamicVolume: Bool, baseVolume: Float) {
        // Soft taps use the small meep, everything else the big one.
        let useSmol = intensity < smolThreshold
        let pool = useSmol ? smolPlayers : bigPlayers
        guard let player = nextPlayer(pool: pool, smol: useSmol) else { return }

        if dynamicVolume {
            // Logarithmic volume scaling: maps intensity [0,1] to [0.2, 1.0].
            let minVol: Float = 0.2
            let maxVol: Float = 1.0
            let scaled = minVol + Float(intensity) * (maxVol - minVol)
            player.volume = baseVolume * scaled
        } else {
            player.volume = baseVolume
        }

        player.currentTime = 0
        player.play()
    }

    /// Round-robins through a pool so overlapping slaps each get their own player.
    /// Swift `class` lets us mutate stored index properties from a non-mutating
    /// method, so we select the pool's index explicitly rather than via keyPath.
    private func nextPlayer(pool: [AVAudioPlayer], smol: Bool) -> AVAudioPlayer? {
        guard !pool.isEmpty else { return nil }
        let i = smol ? smolIndex : bigIndex
        let player = pool[i % pool.count]
        if smol { smolIndex = (i + 1) % pool.count } else { bigIndex = (i + 1) % pool.count }
        return player
    }

    /// Whether the big meep is available for the "Test Meep" menu item.
    var hasSounds: Bool { !bigPlayers.isEmpty || !smolPlayers.isEmpty }
}
