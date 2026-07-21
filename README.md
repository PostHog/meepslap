# MeepSlap 🐤

> Slap your MacBook. It meeps. That's the whole thing.

An internal joke app built on top of the excellent accelerometer work in
[AbdullahFID/MacSlapApp](https://github.com/AbdullahFID/MacSlapApp), stripped
down to a single punchline: the **meep** sound from
[PostHog Code](https://github.com/postHog/code).

You slap the Mac. It meeps. Soft taps get the small meep; hard slaps get the
full meep, louder with force.

## Quick Start

```bash
# Build, install, and launch at login (one command)
make install
```

A 🐤 appears in your menu bar with a running meep count. Slap your MacBook.

To just run it without installing:

```bash
swift build -c release
codesign --force --sign - .build/release/MeepSlap
.build/release/MeepSlap
```

Logs go to stderr (and `/tmp/meepslap.log` when run via the LaunchAgent):

```bash
tail -f /tmp/meepslap.log
```

## Requirements

- macOS 14+ (Sonoma or newer)
- Apple Silicon MacBook (M1 / M2 / M3 / M4 / M5) with a built-in accelerometer
- Xcode Command Line Tools (`xcode-select --install`)

> iMacs, Mac minis, and Mac Pros have no accelerometer, so there's nothing to
> detect. It needs a MacBook.

### Permissions

The app reads the built-in accelerometer via IOKit HID. macOS may require:

1. **Input Monitoring** — System Settings → Privacy & Security → Input Monitoring,
   add your Terminal app (Terminal.app, iTerm2, etc.).
2. If that doesn't work, try running with `sudo` once to bootstrap permissions,
   then quit and run normally.

## How It Works

The MacBook has a **Bosch BMI286 IMU** streaming at ~800 Hz through Apple's
`AppleSPUHIDDevice` sensor processing unit. MeepSlap opens that device directly
via IOKit (no `IOHIDManager`, so no Developer ID signing needed), wakes the
sensor's power/reporting state on the `AppleSPUHIDDriver` service, and feeds raw
22-byte int32 Q16 acceleration reports into an impact detector.

The detector strips gravity with a slow EMA, then gates on **simultaneous high
amplitude *and* high jerk** — the empirically clean separator between a real
slap and hard typing (typing has high-amplitude-but-low-jerk moments, or
high-jerk-but-low-amplitude ones; a slap has both at once). It captures the true
peak force with a short hold window and enforces a refractory period so one
slap's ringing can't re-trigger.

Force maps to volume logarithmically: gentle taps whisper, hard slaps full-volume.

| Impact | Peak amplitude | What happens |
|--------|----------------|--------------|
| Micro | < 0.4 g | small meep, quiet |
| Medium | 0.4 – 1.0 g | big meep |
| Major | ≥ 1.0 g | big meep, full volume + optional flash |

## Menu Bar

Click the 🐤:

```
 Enabled / Disabled
 Test Meep              ← sanity-check the sound
 Sensitivity            → Extremely Sensitive … Requires Significant Force
 Cooldown               → None / Fast / Medium / Slow / Very Slow
 Dynamic Volume         → on/off (force-scaled loudness)

 Effects
 Screen Flash           → on/off + intensity (off by default)

 Volume                 → master slider
 Reset Slap Count
 Quit
```

All settings persist between launches.

## What This Keeps vs. Drops From MacSlapApp

Kept (the genuinely hard parts, verbatim):
- `AccelerometerReader` — IOKit HID streaming of the BMI286 IMU
- `SlapDetector` — the adaptive amplitude+jerk impact detector
- The menu-bar architecture and UserDefaults persistence

Dropped (joke-inappropriate or fragile):
- The 7 voice packs (Sexy, Yamete, Goat, …) → one meep
- USB "moaner" → gone
- Screen shake (private SkyLight API), brightness flash (private DisplayServices
  API), trackpad haptics (private MultitouchSupport API) → replaced with one
  optional, public-API screen flash (off by default)

The audio is self-contained: both meep clips ship in the binary via SwiftPM
resources, so there's no external audio folder to populate.

## Credits

- Accelerometer + detection logic from [AbdullahFID/MacSlapApp](https://github.com/AbdullahFID/MacSlapApp)
- Meep sound from [PostHog Code](https://github.com/postHog/code)

## License

MIT
