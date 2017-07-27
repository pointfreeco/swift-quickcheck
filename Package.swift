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
    .package(url: "https://github.com/pointfreeco/swift-prelude.git", .revision("3c4f6c9")),
  ],
  targets: [
    .target(
      name: "QuickCheck",
      dependencies: ["Either", "LCG", "NonEmpty", "Prelude", "State"]),
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
