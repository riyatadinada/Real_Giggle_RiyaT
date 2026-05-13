// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "PersistenceTestPackage",
    platforms: [.macOS(.v13)],
    products: [],
    targets: [
        .target(
            name: "PersistenceLib",
            dependencies: []
        ),
        .testTarget(
            name: "PersistenceLibTests",
            dependencies: ["PersistenceLib"]
        )
    ]
)
