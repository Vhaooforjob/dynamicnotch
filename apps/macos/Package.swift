// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "NotchFlow",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "NotchFlow", targets: ["NotchFlow"])
    ],
    targets: [
        .executableTarget(
            name: "NotchFlow",
            path: "NotchFlow",
            exclude: ["Resources/Info.plist"],
            resources: [
                .process("Resources")
            ],
            linkerSettings: [
                .linkedLibrary("sqlite3")
            ]
        ),
        .testTarget(
            name: "NotchFlowTests",
            dependencies: ["NotchFlow"],
            path: "NotchFlowTests"
        )
    ]
)
