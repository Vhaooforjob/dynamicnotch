// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DynamicNotch",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "DynamicNotch", targets: ["DynamicNotch"])
    ],
    targets: [
        .executableTarget(
            name: "DynamicNotch",
            path: "DynamicNotch",
            exclude: ["Resources/Info.plist"],
            resources: [
                .process("Resources")
            ],
            linkerSettings: [
                .linkedLibrary("sqlite3"),
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "DynamicNotch/Resources/Info.plist"
                ])
            ]
        ),
        .testTarget(
            name: "DynamicNotchTests",
            dependencies: ["DynamicNotch"],
            path: "DynamicNotchTests"
        )
    ]
)
