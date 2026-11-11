// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LumiPluginStorage",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        // Keep the module/product name stable so existing projects can keep
        // using `import PluginStorage` during the migration.
        .library(name: "PluginStorage", targets: ["PluginStorage"])
    ],
    dependencies: [
        .package(url: "https://github.com/lumi-softworks/LumiProviders.git", from: "1.18.0"),
        .package(url: "https://github.com/lumi-softworks/LumiLogging.git", from: "1.0.1"),
        .package(url: "https://github.com/lumi-softworks/LumiKernel.git", from: "1.1.0")
    ],
    targets: [
        .target(
            name: "PluginStorage",
            dependencies: [
                .product(name: "LumiLoggingKit", package: "LumiLogging"),
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "ProviderStorage", package: "LumiProviders")
            ],
            path: "Sources/PluginStorage"
        ),
        .testTarget(
            name: "PluginStorageTests",
            dependencies: ["PluginStorage"]
        )
    ]
)
