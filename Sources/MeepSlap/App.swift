import SwiftUI

@main
struct MeepSlapApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Optional SwiftUI settings window; the primary UI is the menu bar.
        Settings {
            if let controller = appDelegate.slapController {
                SettingsView()
                    .environmentObject(appDelegate.settings)
                    .environmentObject(controller)
            } else {
                Text("Loading...")
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    let settings = SettingsStore()
    var slapController: MeepSlapController?
    var statusMenu: NSMenu!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon — menu bar app only.
        NSApp.setActivationPolicy(.accessory)

        slapController = MeepSlapController(settings: settings)

        setupMenuBar()
        slapController?.start()
    }

    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.title = "🐤 \(settings.totalSlapCount)"
        }

        statusMenu = NSMenu()
        rebuildMenu()
        statusItem.menu = statusMenu

        NotificationCenter.default.addObserver(
            self, selector: #selector(slapCountChanged),
            name: .slapCountChanged, object: nil
        )
    }

    func rebuildMenu() {
        statusMenu.removeAllItems()

        let enableItem = NSMenuItem(
            title: settings.isEnabled ? "Enabled" : "Disabled",
            action: #selector(toggleEnabled), keyEquivalent: ""
        )
        enableItem.target = self
        enableItem.state = settings.isEnabled ? .on : .off
        statusMenu.addItem(enableItem)

        let testItem = NSMenuItem(title: "Test Meep", action: #selector(testMeep), keyEquivalent: "")
        testItem.target = self
        statusMenu.addItem(testItem)

        statusMenu.addItem(NSMenuItem.separator())

        // Sensitivity submenu
        let sensMenu = NSMenu()
        for level in SensitivityLevel.allCases {
            let item = NSMenuItem(title: level.displayName, action: #selector(selectSensitivity(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = level.rawValue
            item.state = settings.sensitivity == level ? .on : .off
            sensMenu.addItem(item)
        }
        let sensItem = NSMenuItem(title: "Sensitivity", action: nil, keyEquivalent: "")
        sensItem.submenu = sensMenu
        statusMenu.addItem(sensItem)

        // Cooldown submenu
        let cdMenu = NSMenu()
        for cd in CooldownOption.allCases {
            let item = NSMenuItem(title: cd.displayName, action: #selector(selectCooldown(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = cd.interval
            item.state = settings.cooldownInterval == cd.interval ? .on : .off
            cdMenu.addItem(item)
        }
        let cdItem = NSMenuItem(title: "Cooldown", action: nil, keyEquivalent: "")
        cdItem.submenu = cdMenu
        statusMenu.addItem(cdItem)

        // Dynamic volume toggle
        let dynVolItem = NSMenuItem(
            title: "Dynamic Volume",
            action: #selector(toggleDynamicVolume), keyEquivalent: ""
        )
        dynVolItem.target = self
        dynVolItem.state = settings.dynamicVolume ? .on : .off
        statusMenu.addItem(dynVolItem)

        statusMenu.addItem(NSMenuItem.separator())

        // --- Effects ---
        let effectsHeader = NSMenuItem(title: "Effects", action: nil, keyEquivalent: "")
        effectsHeader.isEnabled = false
        statusMenu.addItem(effectsHeader)

        let flashItem = NSMenuItem(
            title: "Screen Flash",
            action: #selector(toggleScreenFlash), keyEquivalent: ""
        )
        flashItem.target = self
        flashItem.state = settings.screenFlashEnabled ? .on : .off
        statusMenu.addItem(flashItem)
        if settings.screenFlashEnabled {
            statusMenu.addItem(createSliderItem(
                value: settings.screenFlashIntensity,
                label: "  Intensity:",
                action: #selector(screenFlashIntensityChanged(_:))
            ))
        }

        statusMenu.addItem(NSMenuItem.separator())

        // Volume slider
        let volSlider = createSliderItem(
            value: Double(settings.volume),
            label: "Volume: \(Int(settings.volume * 100))%",
            action: #selector(volumeChanged(_:))
        )
        statusMenu.addItem(volSlider)

        statusMenu.addItem(NSMenuItem.separator())

        let resetItem = NSMenuItem(title: "Reset Slap Count", action: #selector(resetCount), keyEquivalent: "")
        resetItem.target = self
        statusMenu.addItem(resetItem)

        statusMenu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        statusMenu.addItem(quitItem)
    }

    @objc func toggleEnabled() {
        settings.isEnabled.toggle()
        if settings.isEnabled {
            slapController?.start()
        } else {
            slapController?.stop()
        }
        rebuildMenu()
    }

    @objc func testMeep() {
        slapController?.testMeep()
    }

    @objc func selectSensitivity(_ sender: NSMenuItem) {
        if let raw = sender.representedObject as? Int, let level = SensitivityLevel(rawValue: raw) {
            settings.sensitivity = level
            slapController?.updateDetectorConfig()
        }
        rebuildMenu()
    }

    @objc func selectCooldown(_ sender: NSMenuItem) {
        if let raw = sender.representedObject as? Double {
            settings.cooldownInterval = raw
        }
        rebuildMenu()
    }

    @objc func toggleDynamicVolume() {
        settings.dynamicVolume.toggle()
        rebuildMenu()
    }

    @objc func toggleScreenFlash() {
        settings.screenFlashEnabled.toggle()
        rebuildMenu()
    }

    func createSliderItem(value: Double, label: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem()
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 220, height: 30))
        let labelView = NSTextField(labelWithString: label)
        labelView.frame = NSRect(x: 14, y: 6, width: 80, height: 18)
        labelView.font = NSFont.menuFont(ofSize: 12)
        let slider = NSSlider(value: value, minValue: 0.0, maxValue: 1.0, target: self, action: action)
        slider.frame = NSRect(x: 96, y: 6, width: 110, height: 18)
        slider.tag = 100
        view.addSubview(labelView)
        view.addSubview(slider)
        item.view = view
        return item
    }

    @objc func screenFlashIntensityChanged(_ sender: NSSlider) {
        settings.screenFlashIntensity = sender.doubleValue
        slapController?.screenFlash.intensityMultiplier = sender.doubleValue * 2.0
    }

    @objc func volumeChanged(_ sender: NSSlider) {
        settings.volume = Float(sender.doubleValue)
    }

    @objc func resetCount() {
        settings.totalSlapCount = 0
        slapCountChanged()
    }

    @objc func slapCountChanged() {
        if let button = statusItem?.button {
            if settings.showCountInMenuBar {
                button.title = "🐤 \(settings.totalSlapCount)"
            } else {
                button.title = "🐤"
            }
        }
    }

    @objc func quitApp() {
        NSApp.terminate(nil)
    }
}

extension Notification.Name {
    static let slapCountChanged = Notification.Name("slapCountChanged")
    static let settingsChanged = Notification.Name("settingsChanged")
}
