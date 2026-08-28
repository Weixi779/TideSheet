// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "TideSheet",
    platforms: [
        .iOS(.v17),
    ],
    products: [
        .library(name: "TideSheetUIKit", targets: ["TideSheetUIKit"]),
        .library(name: "TideSheetSwiftUI", targets: ["TideSheetSwiftUI"]),
    ],
    targets: [
        .target(name: "TideSheetDomain"),
        .target(
            name: "TideSheetUIKit",
            dependencies: ["TideSheetDomain"],
            swiftSettings: [
                .defaultIsolation(MainActor.self),
            ]
        ),
        .target(
            name: "TideSheetSwiftUI",
            dependencies: ["TideSheetDomain"],
            swiftSettings: [
                .defaultIsolation(MainActor.self),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
