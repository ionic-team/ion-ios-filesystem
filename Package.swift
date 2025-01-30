// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "IONFilesystemLib",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "IONFilesystemLib",
            targets: ["IONFilesystemLib"]
        )
    ],
    targets: [
        .target(
            name: "IONFilesystemLib",
            path: "IONFilesystemLib"
        ),
        .testTarget(
            name: "IONFilesystemLibTests",
            dependencies: ["IONFilesystemLib"],
            path: "IONFilesystemLibTests"
        )
    ]
)
