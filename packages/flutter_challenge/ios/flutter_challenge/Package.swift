// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "flutter_challenge",
    platforms: [.iOS("15.0")],
    products: [
        .library(name: "flutter-challenge", type: .dynamic, targets: ["flutter_challenge"]),
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
    ],
    targets: [
        .binaryTarget(
            name: "ChallengeCore",
            path: "Frameworks/ChallengeCore.xcframework"
        ),
        .target(
            name: "flutter_challenge",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                "ChallengeCore",
            ],
            path: "Sources/flutter_challenge"
        ),
    ]
)
