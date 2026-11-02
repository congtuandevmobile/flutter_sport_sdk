// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "flutter_workout",
    platforms: [.iOS("15.0")],
    products: [
        .library(name: "flutter-workout", targets: ["flutter_workout"]),
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
    ],
    targets: [
        .binaryTarget(
            name: "WorkoutCore",
            path: "../Frameworks/WorkoutCore.xcframework"
        ),
        .target(
            name: "flutter_workout",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                "WorkoutCore",
            ],
            path: "Sources/flutter_workout"
        ),
    ]
)
