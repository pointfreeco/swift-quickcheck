// swift-tools-version:4.0

import PackageDescription

let package = Package(
  name: "QuickCheck",
  products: [
    .library(name: "QuickCheck", targets: ["QuickCheck"]),
    .library(name: "LCG", targets: ["LCG"]),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-prelude.git", .revision("2778d80")),
  ],
  targets: [
    .target(
      name: "QuickCheck",
      dependencies: ["Either", "LCG", "NonEmpty", "Prelude", "State"]),
    .target(
      name: "LCG",
      dependencies: ["Prelude"]),
    .testTarget(
      name: "QuickCheckTests",
      dependencies: ["QuickCheck"]),
  ]
)
