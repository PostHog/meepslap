import SwiftUI

/// Optional SwiftUI settings window. Mirrors the menu bar controls; most users
/// will just use the menu bar, but this gives a friendlier surface for the
/// sliders. The menu bar is the primary UI.
struct SettingsView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var controller: MeepSlapController

    var body: some View {
        Form {
            Section("Detection") {
                Picker("Sensitivity", selection: $settings.sensitivity) {
                    ForEach(SensitivityLevel.allCases, id: \.self) { level in
                        Text(level.displayName).tag(level)
                    }
                }
                .onChange(of: settings.sensitivity) { _, _ in
                    controller.updateDetectorConfig()
                }

                Picker("Cooldown", selection: $settings.cooldownInterval) {
                    ForEach(CooldownOption.allCases, id: \.self) { cd in
                        Text(cd.displayName).tag(cd.interval)
                    }
                }

                Toggle("Enabled", isOn: $settings.isEnabled)
                    .onChange(of: settings.isEnabled) { _, on in
                        if on { controller.start() } else { controller.stop() }
                    }
            }

            Section("Audio") {
                Toggle("Dynamic Volume", isOn: $settings.dynamicVolume)
                Slider(value: $settings.volume, in: 0...1) {
                    Text("Volume")
                } minimumValueLabel: {
                    Text("0%")
                } maximumValueLabel: {
                    Text("100%")
                }

                Button("Test Meep") { controller.testMeep() }
            }

            Section("Effects") {
                Toggle("Screen Flash", isOn: $settings.screenFlashEnabled)
                if settings.screenFlashEnabled {
                    Slider(value: $settings.screenFlashIntensity, in: 0...1) {
                        Text("Flash Intensity")
                    }
                    .onChange(of: settings.screenFlashIntensity) { _, value in
                        controller.screenFlash.intensityMultiplier = value * 2.0
                    }
                }
            }

            Section("Stats") {
                Toggle("Show count in menu bar", isOn: $settings.showCountInMenuBar)
                HStack {
                    Text("Total meeps")
                    Spacer()
                    Text("\(settings.totalSlapCount)").foregroundStyle(.secondary)
                }
                Button("Reset Slap Count") {
                    settings.totalSlapCount = 0
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 420)
    }
}
