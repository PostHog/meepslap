// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MeepSlap",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "MeepSlap",
            path: "Sources/MeepSlap",
            resources: [
                // PostHog's meep.mp3 + meep-smol.mp3, bundled so the app is
                // self-contained (no external audio folder needed).
                .copy("Resources"),
            ],
            linkerSettings: [
                .linkedFramework("IOKit"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("AppKit"),
            ]
        )
    ]
)
