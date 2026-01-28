// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Utilities",
  defaultLocalization: "en",
  platforms: [
    .iOS(.v18)
  ],
  products: [
    .library(
      name: "Utilities",
      targets: ["Utilities"]
    )
  ],
  targets: [
    .target(
      name: "Utilities",
      swiftSettings: [
        .swiftLanguageMode(.v6)
      ]
    )
  ]
)
