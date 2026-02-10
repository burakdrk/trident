// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "DataModels",
  defaultLocalization: "en",
  platforms: [
    .iOS(.v18)
  ],
  products: [
    .library(
      name: "DataModels",
      targets: ["DataModels"]
    )
  ],
  dependencies: [
    .package(name: "Utilities", path: "../Utilities")
  ],
  targets: [
    .target(
      name: "DataModels",
      dependencies: [
        .product(name: "Utilities", package: "Utilities")
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableUpcomingFeature("InferIsolatedConformances")
      ]
    )
  ]
)
