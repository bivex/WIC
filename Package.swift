// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WIC",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "WIC",
            targets: ["WIC"]
        )
    ],
    targets: [
        .executableTarget(
            name: "WIC",
            path: "WIC",
            exclude: ["Info.plist", "Managers/WindowManager.swift.backup"],
            sources: [
                "WICApp.swift",
                "Models/WindowPosition.swift",
                "Managers/WindowManager.swift",
                "Managers/HotkeyManager.swift",
                "Helpers/AccessibilityHelper.swift",
                "Helpers/Logger.swift",
                "Views/ContentView.swift",
                "Views/SettingsView.swift",
                "Views/AutoLayoutView.swift"
            ]
        ),
        .testTarget(
            name: "WICTests",
            dependencies: ["WIC"],
            path: "Tests"
        )
    ]
)
