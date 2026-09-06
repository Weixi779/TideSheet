// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "TideSheet",
    platforms: [
        .iOS(.v17),
    ],
    products: [
        .library(name: "TideSheetUIKit", targets: ["TideSheet", "TideSheetUIKit"]),
        .library(name: "TideSheetSwiftUI", targets: ["TideSheet", "TideSheetSwiftUI"]),
    ],
    targets: [
        .target(name: "TideSheet"),
        .target(
            name: "TideSheetUIKit",
            dependencies: ["TideSheet"],
            swiftSettings: [
                .defaultIsolation(MainActor.self),
            ],
        ),
        .target(
            name: "TideSheetSwiftUI",
            dependencies: ["TideSheet"],
            swiftSettings: [
                .defaultIsolation(MainActor.self),
            ],
        ),
        .testTarget(
            name: "TideSheetTests",
            dependencies: ["TideSheet"],
        ),
    ],
    swiftLanguageModes: [.v6],
)
