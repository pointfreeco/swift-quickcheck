import Prelude
import Foundation

public let M = 48271
public let C = 0
public let N = 2147483647

public struct Seed {
  static let min = 1
  static let max = N - 1
  
  public let seed: Int
  
  public init(_ seed: Int) {
    self.seed = (ensureBetween(Seed.min..<Seed.max) <| seed)
  }
  
  public static func random() -> IO<Seed> {
    return IO { Seed(Int(arc4random_uniform(UInt32(N)))) }
  }
}

public func next(_ seed: Seed) -> Seed {
  return perturb(Double(C)) <| seed
}

public func perturb(_ d: Double) -> (Seed) -> (Seed) {
  func go(_ n: Int) -> Int {
    return Int((Double(M) * Double(n) + d).truncatingRemainder(dividingBy: Double(N)))
  }
  return Seed.init <<< go <<< get(\.seed)
}

private func ensureBetween(_ range: Range<Int>) -> (Int) -> Int {
  return { n in
    let nPrime = n % range.count
    return nPrime < range.lowerBound ? nPrime + range.upperBound : nPrime
  }
}
