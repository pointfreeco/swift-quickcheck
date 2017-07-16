// swift-tools-version:4.0

import PackageDescription

let package = Package(
  name: "QuickCheck",
  products: [
    .library(name: "QuickCheck", targets: ["QuickCheck"]),
    .library(name: "LCG", targets: ["LCG"]),
    .library(name: "NonEmpty", targets: ["NonEmpty"]),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-prelude.git", .branch("master")),
  ],
  targets: [
    .target(
      name: "QuickCheck",
      dependencies: ["Prelude", "LCG", "Either", "NonEmpty"]),
    .target(
      name: "LCG",
      dependencies: ["Prelude"]),
    .target(
      name: "NonEmpty",
      dependencies: ["Prelude"]),
    .testTarget(
      name: "QuickCheckTests",
      dependencies: ["QuickCheck"]),
  ]
)
