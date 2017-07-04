import Prelude

infix operator >|: infixr5 // NonEmpty

public struct NonEmpty<S: Sequence> {
  let head: S.Element
  let tail: S
}

public func >| <S>(head: S.Element, tail: S) -> NonEmpty<S> {
  return .init(head: head, tail: tail)
}

public func uncons<S>(_ xs: NonEmpty<S>) -> (S.Element, S) {
  return (xs.head, xs.tail)
}
