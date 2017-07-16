import Prelude
import QuickCheck

struct User: Decodable {
  let id: Int
  let name: String
}

dump(
  User.arbitrary()
)
