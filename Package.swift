// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LanScanner",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "LanScanner",
            targets: ["LanScanner"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "LanScanner",
            resources: [.copy("Resources/data.plist")],
            publicHeadersPath: "include",
            cSettings: [.headerSearchPath("Code")]),
        .testTarget(
            name: "LanScannerTests",
            dependencies: ["LanScanner"]),
    ]
)
