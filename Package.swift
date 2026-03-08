// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "Beautiful-Stocks",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .executable(name: "Beautiful-Stocks", targets: ["Beautiful-Stocks"]),
    ],
    targets: [
        .executableTarget(
            name: "Beautiful-Stocks",
            path: ".",
            sources: [
                "App",
                "Logic",
                "Models",
                "Services",
                "Utilities",
                "ViewModels",
                "Views"
            ],
            exclude: [
                "README.md",
                "Package.swift"
            ],
            linkerSettings: [
                .linkedFramework("Charts")
            ]
        )
    ],
    swiftLanguageVersions: [.v5]
)
