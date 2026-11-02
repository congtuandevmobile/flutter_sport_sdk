// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "flutter_sport_ble",
    platforms: [.iOS("15.0")],
    products: [
        .library(name: "flutter-sport-ble", targets: ["flutter_sport_ble"]),
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
    ],
    targets: [
        .binaryTarget(
            name: "SensorCore",
            path: "../Frameworks/SensorCore.xcframework"
        ),
        .target(
            name: "flutter_sport_ble",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                "SensorCore",
            ],
            path: "Sources/flutter_sport_ble",
            linkerSettings: [
                .linkedFramework("CoreBluetooth"),
            ]
        ),
    ]
)
