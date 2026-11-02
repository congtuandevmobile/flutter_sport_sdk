// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "flutter_tracking_gps",
    platforms: [.iOS("15.0")],
    products: [
        .library(name: "flutter-tracking-gps", type: .dynamic, targets: ["flutter_tracking_gps"]),
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
    ],
    targets: [
        .binaryTarget(
            name: "TrackingCore",
            path: "Frameworks/TrackingCore.xcframework"
        ),
        .target(
            name: "flutter_tracking_gps",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                "TrackingCore",
            ],
            path: "Sources/flutter_tracking_gps",
            resources: [.process("PrivacyInfo.xcprivacy")],
            linkerSettings: [
                .linkedFramework("CoreLocation"),
                .linkedFramework("CoreMotion"),
            ]
        ),
    ]
)
