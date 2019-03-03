// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "BoostCore",
    products: [
        .library(name: "BoostCore", targets: ["BoostCore"]),
        .library(name: "BoostCoreTestTools", targets: ["BoostCoreTestTools"]),
        .executable(name: "BoostRun", targets: ["BoostRun"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "3.0.0"),
        .package(url: "https://github.com/vapor/fluent-postgresql.git", from: "1.0.0-rc.4"),
        .package(url: "https://github.com/kareman/SwiftShell.git", from: "4.0.2"),
        .package(url: "https://github.com/LiveUI/S3.git", .branch("master")),
        .package(url: "https://github.com/LiveUI/ErrorsCore.git", .branch("master")),
        .package(url: "https://github.com/LiveUI/ApiCore.git", .branch("master")),
        .package(url: "https://github.com/LiveUI/MailCore.git", .branch("master")),
        .package(url: "https://github.com/LiveUI/SettingsCore.git", .branch("master")),
        .package(url: "https://github.com/LiveUI/VaporTestTools.git", from: "0.1.5"),
        .package(url: "https://github.com/LiveUI/FluentTestTools.git", .branch("master")),
        .package(url: "https://github.com/LiveUI/Configure.git", .branch("master")),
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
            name: "BoostApp",
            dependencies: [
                "Vapor",
                "BoostCore"
            ]
        ),
        .target(
            name: "BoostRun",
            dependencies: [
                "BoostApp"
            ]
        ),
        .target(
            name: "BoostCore",
            dependencies: [
                "Vapor",
                "Fluent",
                "FluentPostgreSQL",
                "ApiCore",
                "ErrorsCore",
                "SwiftShell",
                "MailCore",
                "SettingsCore",
                "S3",
                "Configure",
                "Normalized"
            ]
        ),
        .target(
            name: "BoostCoreTestTools",
            dependencies: [
                "Vapor",
                "ApiCore",
                "BoostCore",
                "VaporTestTools",
                "ApiCoreTestTools",
                "MailCoreTestTools"
            ]
        ),
        .testTarget(
            name: "BoostCoreTests",
            dependencies: [
                "BoostCore",
                "VaporTestTools",
                "FluentTestTools",
                "ApiCoreTestTools",
                "BoostCoreTestTools"
            ]
        )
    ]
)
