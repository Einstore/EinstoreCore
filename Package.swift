// swift-tools-version:4.2
import PackageDescription

let package = Package(
    name: "EinstoreCore",
    products: [
        .library(name: "EinstoreCore", targets: ["EinstoreCore"]),
        .library(name: "EinstoreCoreTestTools", targets: ["EinstoreCoreTestTools"]),
        .executable(name: "EinstoreRun", targets: ["EinstoreRun"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "3.0.0"),
        .package(url: "https://github.com/vapor/fluent-postgresql.git", from: "1.0.0"),
        .package(url: "https://github.com/kareman/SwiftShell.git", from: "5.1.0"),
        .package(url: "https://github.com/LiveUI/S3.git", from: "3.0.1"),
        .package(url: "https://github.com/LiveUI/ErrorsCore.git", from: "0.1.0"),
        .package(url: "https://github.com/LiveUI/ApiCore.git", from: "1.0.2"),
        .package(url: "https://github.com/LiveUI/MailCore.git", from: "3.1.2"),
        .package(url: "https://github.com/LiveUI/VaporTestTools.git", from: "0.1.5"),
        .package(url: "https://github.com/LiveUI/FluentTestTools.git", from: "0.1.0"),
        .package(url: "https://github.com/apple/swift-nio-zlib-support.git", from: "1.0.0")
    ],
    targets: [
        .target(name: "Czlib"),
        .target(
            name: "Normalized",
            dependencies: [
                "Czlib"
            ]
        ),
        .target(
            name: "EinstoreApp",
            dependencies: [
                "Vapor",
                "EinstoreCore"
            ]
        ),
        .target(
            name: "EinstoreRun",
            dependencies: [
                "EinstoreApp"
            ]
        ),
        .target(
            name: "EinstoreCore",
            dependencies: [
                "Vapor",
                "Fluent",
                "FluentPostgreSQL",
                "ApiCore",
                "ErrorsCore",
                "SwiftShell",
                "MailCore",
                "S3",
                "Normalized"
            ]
        ),
        .target(
            name: "EinstoreCoreTestTools",
            dependencies: [
                "Vapor",
                "ApiCore",
                "EinstoreCore",
                "VaporTestTools",
                "ApiCoreTestTools",
                "MailCoreTestTools"
            ]
        ),
        .testTarget(
            name: "EinstoreCoreTests",
            dependencies: [
                "EinstoreCore",
                "VaporTestTools",
                "FluentTestTools",
                "ApiCoreTestTools",
                "EinstoreCoreTestTools"
            ]
        )
    ]
)
