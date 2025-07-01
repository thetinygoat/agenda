// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "agenda",
    products: [
        .executable(name: "agenda", targets: ["agenda"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0")
    ],
    targets: [
        .executableTarget(
            name: "agenda",
            dependencies: [.product(name: "ArgumentParser", package: "swift-argument-parser")])
    ]
)
