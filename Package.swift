// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

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
        .library(
            name: "LambdaspireSwiftDDD",
            targets: ["LambdaspireSwiftDDD"])
    ],
    dependencies: [
        
        // Lambdaspire
        .package(
            url: "https://github.com/Lambdaspire/Lambdaspire-Swift-DependencyResolution",
            from: "1.0.0"),
        .package(
            url: "https://github.com/Lambdaspire/Lambdaspire-Swift-Abstractions",
            from: "1.0.0"),
        .package(
            url: "https://github.com/Lambdaspire/Lambdaspire-Swift-Logging",
            from: "1.0.0"),
        
        // Apple
        .package(
            url: "https://github.com/apple/swift-syntax",
            from: "509.0.0")
    ],
    targets: [
        
        // Macros and Macros Tests
        .macro(
            name: "LambdaspireSwiftDDDMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        .testTarget(
            name: "LambdaspireSwiftDDDMacrosTests",
            dependencies: [
                "LambdaspireSwiftDDDMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
        
        // Library and Library Tests
        .target(
            name: "LambdaspireSwiftDDD",
            dependencies: [
                "LambdaspireSwiftDDDMacros",
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
