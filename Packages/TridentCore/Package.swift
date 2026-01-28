// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "TridentCore",
  defaultLocalization: "en",
  platforms: [
    .iOS(.v18)
  ],
  products: [
    .library(
      name: "TridentCore",
      targets: ["TridentCore"]
    )
  ],
  dependencies: [
    .package(name: "DataModels", path: "../DataModels"),
    .package(name: "Utilities", path: "../Utilities"),
    .package(url: "https://github.com/burakdrk/TwitchIRC", branch: "main"),
    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.10.0"),
    .package(url: "https://github.com/apple/swift-async-algorithms", from: "1.0.4"),
    .package(url: "https://github.com/auth0/SimpleKeychain", from: "1.3.0"),
    .package(url: "https://github.com/Alamofire/Alamofire", from: "5.10.2")
  ],
  targets: [
    .target(
      name: "TridentCore",
      dependencies: [
        .product(name: "DataModels", package: "DataModels"),
        .product(name: "Utilities", package: "Utilities"),
        .product(name: "TwitchIRC", package: "TwitchIRC"),
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
        .product(name: "SimpleKeychain", package: "SimpleKeychain"),
        .product(name: "Alamofire", package: "Alamofire")
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableUpcomingFeature("InferIsolatedConformances")
      ]
    ),
    .testTarget(
      name: "TridentCoreTests",
      dependencies: ["TridentCore"]
    )
  ]
)
