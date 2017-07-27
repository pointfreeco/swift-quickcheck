import Prelude
import Either
import LCG
import NonEmpty

public typealias GenState = (newSeed: Seed, size: Int)
public typealias Gen<A> = State<GenState, A>

public func repeatable<A, B>(_ f: @escaping (A) -> Gen<B>) -> Gen<(A) -> B> {
  return .init { s in
    ({ a in f(a).run(s).result }, (newSeed: next(s.newSeed), size: s.size))
  }
}

public func stateful<A>(_ f: @escaping (GenState) -> Gen<A>) -> Gen<A> {
  return .init { s in f(s).run(s) }
}

public func variant<A>(_ newSeed: Seed) -> (Gen<A>) -> Gen<A> {
  return { gen in
    .init { gen.run((newSeed, $0.size)) }
  }
}

public func suchThat<A>(_ gen: Gen<A>) -> (@escaping (A) -> Bool) -> Gen<A> {
  return { pred in
    .init { state in
      var nextState = state
      var result: A
      repeat {
        (result, nextState) = gen.run(nextState)
      } while !pred(result)
      return (result, nextState)
    }
  }
}

public func sized<A>(_ f: @escaping (Int) -> Gen<A>) -> Gen<A> {
  return stateful { f($0.size) }
}

public func resize<A>(_ size: Int) -> (Gen<A>) -> Gen<A> {
  return { gen in
    .init { gen.run((newSeed: $0.newSeed, size)) }
  }
}

public func scale<A>(_ f: @escaping (Int) -> Int) -> (Gen<A>) -> Gen<A> {
  return { gen in
    sized { $0 |> f >>> resize <| gen }
  }
}

public func choose(_ range: Range<Double>) -> Gen<Double> {
  return uniform.map { (range.upperBound - range.lowerBound) * $0 + range.lowerBound }
}

public func choose(_ range: CountableRange<Int>) -> Gen<Int> {
  let choose31BitPosNumber = lcgStep.map(Double.init)
  let choose32BitPosNumber = curry(+)
    <¢> choose31BitPosNumber
    <*> ({ $0 * 2 } <¢> choose31BitPosNumber)
  
  let (min, max) = (Double(range.lowerBound), Double(range.upperBound))
  let clamp: (Double) -> Double = { min + $0.truncatingRemainder(dividingBy: max - min + 1) }
  
  return (Int.init <<< { $0.rounded(.down) } <<< clamp) <¢> choose32BitPosNumber
}

public func oneOf<A>(_ x: Gen<A>, _ xs: Gen<A>...) -> Gen<A> {
  return oneOf <| x >| xs
}

public func oneOf<A>(_ xs: NonEmpty<[Gen<A>]>) -> Gen<A> {
  let (head, tail) = xs |> uncons
  return choose(0..<tail.endIndex) >>- { $0 == 0 ? head : tail[$0 - 1] }
}

public func array<A>(of gen: Gen<A>) -> Gen<[A]> {
  return sized { n in
    choose(0..<n)
      .flatMap { k in vector(of: k) <| gen }
  }
}

public func nonEmptyArray<A>(of gen: Gen<A>) -> Gen<NonEmpty<[A]>> {
  return sized { n in
    choose(0..<n)
      .flatMap { k in
        gen.flatMap { x in
          (vector(of: k - 1) <| gen).flatMap { xs in
            pure(x >| xs)
          }
        }
    }
  }
}

public func vector<A>(of size: Int) -> (Gen<A>) -> Gen<[A]> {
  return { gen in
    .init { state in
      let maxSize = max(0, size)
      var nextState = state
      var xs: [A] = []
      xs.reserveCapacity(maxSize)
      for _ in 0..<maxSize {
        let pair = gen.run(nextState)
        xs.append(pair.result)
        nextState = pair.finalState
      }
      return (xs, nextState)
    }
  }
}

public func elements<A>(_ x: A, _ xs: A...) -> Gen<A> {
  return elements <| x >| xs
}

public func elements<A>(_ xs: NonEmpty<[A]>) -> Gen<A> {
  let (head, tail) = xs |> uncons
  return choose(0..<tail.endIndex)
    .map { $0 == 0 ? head : tail[$0 - 1] }
}

public func shuffle<A>(_ xs: [A]) -> Gen<[A]> {
  return (vector(of: xs.count) <| choose(0..<Int.max))
    .map { ns in zip(ns, xs).sorted(by: { $0.0 < $1.0 }).map(second) }
}

public let lcgStep = Gen { ($0.newSeed.seed, (next($0.newSeed), $0.size)) }

public let uniform = lcgStep.map { Double($0) / Double(N) }

public func perturbGen<A>(_ by: Double) -> (Gen<A>) -> Gen<A> {
  return { gen in
    .init {
      gen.run((newSeed: perturb(Double(Float32(2).bitPattern)) <| $0.newSeed, size: $0.size))
    }
  }
}

public func choose<A>(_ a1: Gen<A>, _ a2: Gen<A>) -> Gen<A> {
  return genBool.flatMap { $0 ? a1 : a2 }
}

public let genBool = uniform.map { $0 < 0.5 }

public let genUnicodeScalar =
  ((choose(0..<65_536).map { UnicodeScalar($0) } |> suchThat) <| { $0 != nil })
  .map { $0! }

public let genCharacter = genUnicodeScalar.map(Character.init)

public let genDouble = uniform

public let genInt = choose(-1_000_000..<1_000_000)

public let genString = array(of: genCharacter).map { String($0) }

public let genUnit: Gen<Unit> = pure(unit)

public func optional<A>(of gen: Gen<A>) -> Gen<A?> {
  return uniform
    .flatMap { $0 < 0.75
      ? gen.map(Optional.some)
      : pure(.none)
  }
}

public func tuple<A, B>(of a: Gen<A>, and b: Gen<B>) -> Gen<(A, B)> {
  return { a in { b in (a, b) } } <¢> a <*> b
}

public func either<L, R>(of l: Gen<L>, or r: Gen<R>) -> Gen<Either<L, R>> {
  return choose(l.map(Either.left), r.map(Either.right))
}
