// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LambdaspireSwiftDDD",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v10),
        .tvOS(.v17),
        .visionOS(.v1)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "LambdaspireSwiftDDD",
            targets: ["LambdaspireSwiftDDD"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/Lambdaspire/Lambdaspire-Swift-DependencyResolution",
            from: "1.0.0"),
        .package(
            url: "https://github.com/Lambdaspire/Lambdaspire-Swift-Abstractions",
            from: "1.0.0"),
        .package(
            url: "https://github.com/Lambdaspire/Lambdaspire-Swift-Logging",
            from: "1.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "LambdaspireSwiftDDD",
            dependencies: [
                .product(name: "LambdaspireAbstractions", package: "Lambdaspire-Swift-Abstractions")
            ]),
        .testTarget(
            name: "LambdaspireSwiftDDDTests",
            dependencies: [
                "LambdaspireSwiftDDD",
                .product(name: "LambdaspireDependencyResolution", package: "Lambdaspire-Swift-DependencyResolution"),
                .product(name: "LambdaspireLogging", package: "Lambdaspire-Swift-Logging"),
            ]),
    ]
)
