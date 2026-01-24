// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Models",
  defaultLocalization: "en",
  platforms: [
    .iOS(.v26)
  ],
  products: [
    .library(
      name: "Models",
      targets: ["Models"]
    )
  ],
  dependencies: [
    .package(name: "Utilities", path: "../Utilities"),
    .package(url: "https://github.com/burakdrk/TwitchIRC", branch: "main")
  ],
  targets: [
    .target(
      name: "Models",
      dependencies: [
        .product(name: "Utilities", package: "Utilities"),
        .product(name: "TwitchIRC", package: "TwitchIRC")
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6)
      ]
    ),
    .testTarget(
      name: "ModelsTests",
      dependencies: ["Models"]
    )
  ]
)
