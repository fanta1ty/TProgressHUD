// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TProgressHUD",
    platforms: [.iOS(.v12)],
    products: [
        .library(
            name: "TProgressHUD",
            targets: ["TProgressHUD"]),
    ],
    targets: [
        .target(
            name: "TProgressHUD",
            resources: [
                .process("Resources")
            ]),
        .testTarget(
            name: "TProgressHUDTests",
            dependencies: ["TProgressHUD"])
    ]
)
